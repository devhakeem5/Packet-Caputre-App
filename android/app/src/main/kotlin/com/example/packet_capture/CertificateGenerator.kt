package com.example.packet_capture

import android.content.Context
import android.util.Log
import org.bouncycastle.asn1.x500.X500Name
import org.bouncycastle.asn1.x509.BasicConstraints
import org.bouncycastle.asn1.x509.Extension
import org.bouncycastle.asn1.x509.GeneralName
import org.bouncycastle.asn1.x509.GeneralNames
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo
import org.bouncycastle.cert.X509v3CertificateBuilder
import org.bouncycastle.cert.jcajce.JcaX509CertificateConverter
import org.bouncycastle.cert.jcajce.JcaX509v3CertificateBuilder
import org.bouncycastle.jce.provider.BouncyCastleProvider
import org.bouncycastle.operator.jcajce.JcaContentSignerBuilder
import org.bouncycastle.openssl.PEMParser
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter
import java.io.File
import java.io.FileReader
import java.math.BigInteger
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.SecureRandom
import java.security.Security
import java.security.cert.X509Certificate
import java.util.Date
import java.util.concurrent.ConcurrentHashMap
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManagerFactory

object CertificateGenerator {
    private const val TAG = "CertGenerator"
    
    private var caCert: X509Certificate? = null
    private var caKey: PrivateKey? = null
    
    // Cache: Hostname -> KeyStore (containing Key and Cert)
    private val keyStoreCache = ConcurrentHashMap<String, KeyStore>()
    
    // Shared KeyPair for all leaf certs to save CPU (common optimization)
    private var sharedKeyPair: KeyPair? = null

    init {
        Security.addProvider(BouncyCastleProvider())
    }

    fun init(context: Context) {
        try {
            // Load CA from files dir
            val caHeaderFile = File(context.filesDir, "ca.crt")
            val caKeyFile = File(context.filesDir, "ca.key")

            if (!caHeaderFile.exists() || !caKeyFile.exists()) {
                Log.d(TAG, "CA files missing. Generating new Root CA...")
                generateAndSaveRootCa(context, caHeaderFile, caKeyFile)
            }

            if (caHeaderFile.exists() && caKeyFile.exists()) {
                loadCa(caHeaderFile, caKeyFile)
                // Pre-generate a keypair for leaf certs
                val kpg = KeyPairGenerator.getInstance("RSA", "BC")
                kpg.initialize(2048)
                sharedKeyPair = kpg.generateKeyPair()
                Log.d(TAG, "CertificateGenerator initialized successfully")
            } else {
                Log.e(TAG, "FATAL: CA files still not found after generation attempt")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize CertificateGenerator", e)
        }
    }

    private fun generateAndSaveRootCa(context: Context, certFile: File, keyFile: File) {
        try {
            val kpg = KeyPairGenerator.getInstance("RSA", "BC")
            kpg.initialize(2048)
            val caKeyPair = kpg.generateKeyPair()

            val issuer = X500Name("CN=PacketCapture CA, O=PacketCapture, L=Local")
            val serial = BigInteger(64, SecureRandom())
            val notBefore = Date(System.currentTimeMillis() - 1000 * 60 * 60)
            val notAfter = Date(System.currentTimeMillis() + 1000L * 60 * 60 * 24 * 365 * 10) // 10 years

            val builder = JcaX509v3CertificateBuilder(
                issuer,
                serial,
                notBefore,
                notAfter,
                issuer, // Self-signed
                caKeyPair.public
            )

            builder.addExtension(Extension.basicConstraints, true, BasicConstraints(true))
            builder.addExtension(
                    Extension.keyUsage, true,
                     org.bouncycastle.asn1.x509.KeyUsage(
                             org.bouncycastle.asn1.x509.KeyUsage.keyCertSign or org.bouncycastle.asn1.x509.KeyUsage.cRLSign
                     )
            )

            val signer = JcaContentSignerBuilder("SHA256WithRSAEncryption")
                .setProvider("BC")
                .build(caKeyPair.private)

            val certHolder = builder.build(signer)
            val cert = JcaX509CertificateConverter().setProvider("BC").getCertificate(certHolder)

            // Save Cert
            val certPem = convertToPem(cert)
            certFile.writeText(certPem)

            // Save Key
            val keyPem = convertToPem(caKeyPair.private)
            keyFile.writeText(keyPem)

            Log.d(TAG, "Root CA generated and saved to ${context.filesDir}")

        } catch (e: Exception) {
            Log.e(TAG, "Failed to generate Root CA", e)
            throw e
        }
    }

    private fun convertToPem(obj: Any): String {
        val writer = java.io.StringWriter()
        val pemWriter = org.bouncycastle.openssl.jcajce.JcaPEMWriter(writer)
        pemWriter.writeObject(obj)
        pemWriter.close()
        return writer.toString()
    }

    private fun loadCa(certFile: File, keyFile: File) {
        // Load Cert
        val certParser = PEMParser(FileReader(certFile))
        val certHolder = certParser.readObject() 
        // Depending on format, certHolder might be X509CertificateHolder or similar
        // Convert to JCA
        caCert = JcaX509CertificateConverter().setProvider("BC").getCertificate(certHolder as org.bouncycastle.cert.X509CertificateHolder)
        certParser.close()
        
        // Load Key
        val keyParser = PEMParser(FileReader(keyFile))
        val keyObject = keyParser.readObject()
        // Handle various key formats (PKCS8, PKCS1, etc)
        val converter = JcaPEMKeyConverter().setProvider("BC")
        caKey = if (keyObject is org.bouncycastle.pkcs.PKCS8EncryptedPrivateKeyInfo) {
             // Not supporting encrypted keys for simplicity right now (or handle generic)
             throw RuntimeException("Encrypted keys not supported yet")
        } else if (keyObject is org.bouncycastle.openssl.PEMKeyPair) {
            converter.getKeyPair(keyObject).private
        } else if (keyObject is org.bouncycastle.asn1.pkcs.PrivateKeyInfo) {
            converter.getPrivateKey(keyObject)
        } else {
             // Fallback or error
             null
        }
        keyParser.close()
    }
    
    fun getSslContextForHost(host: String): SSLContext {
        if (caCert == null || caKey == null) {
            throw RuntimeException("Generator not initialized")
        }
        
        var keyStore = keyStoreCache[host]
        if (keyStore == null) {
            keyStore = generateKeyStoreForHost(host)
            keyStoreCache[host] = keyStore
        }
        
        val keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())
        keyManagerFactory.init(keyStore, "password".toCharArray())
        
        val trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
        trustManagerFactory.init(null as KeyStore?) // Trust system certs for upstream connection?
        // Wait, trust managers here are for the SERVER socket (to trust clients? no, usually empty)
        
        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(keyManagerFactory.keyManagers, null, SecureRandom()) 
        return sslContext
    }

    private fun generateKeyStoreForHost(host: String): KeyStore {
        val keys = sharedKeyPair ?: throw RuntimeException("Shared KeyPair not init")
        
        // Prepare Certificate Builder
        val serial = BigInteger(64, SecureRandom())
        val notBefore = Date(System.currentTimeMillis() - 1000 * 60 * 60) // 1 hour ago
        val notAfter = Date(System.currentTimeMillis() + 1000L * 60 * 60 * 24 * 365) // 1 year
        
        val issuer = X500Name(caCert!!.subjectX500Principal.name)
        val subject = X500Name("CN=$host, O=PacketCapture, L=Local")
        
        // Subject Public Key
        val subPubKeyInfo = SubjectPublicKeyInfo.getInstance(keys.public.encoded)
        
        val builder = JcaX509v3CertificateBuilder(
            issuer,
            serial,
            notBefore,
            notAfter,
            subject,
            keys.public
        )
        
        // Add SAN (Subject Alternative Name) - Critical for modern Android/Chrome
        val generalNames = GeneralNames(GeneralName(GeneralName.dNSName, host))
        builder.addExtension(Extension.subjectAlternativeName, false, generalNames)
        
        // Basic Constraints (Not CA)
        builder.addExtension(Extension.basicConstraints, true, BasicConstraints(false))
        
        // Sign
        val signer = JcaContentSignerBuilder("SHA256WithRSAEncryption")
            .setProvider("BC")
            .build(caKey)
            
        val certHolder = builder.build(signer)
        val cert = JcaX509CertificateConverter().setProvider("BC").getCertificate(certHolder)
        
        // Create KeyStore
        val keyStore = KeyStore.getInstance("PKCS12")
        keyStore.load(null, null)
        
        val chain = arrayOf(cert, caCert)
        keyStore.setKeyEntry(host, keys.private, "password".toCharArray(), chain)
        
        Log.d(TAG, "Generated certificate for $host")
        return keyStore
    }
}
