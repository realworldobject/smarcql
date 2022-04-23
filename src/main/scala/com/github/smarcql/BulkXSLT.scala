package com.github.smarcql

import org.apache.hadoop.io.compress.GzipCodec
import org.apache.jena.rdf.model.ModelFactory
import org.apache.log4j.{Level, Logger}
import org.apache.spark.{SparkConf, SparkContext}

import java.io.{ByteArrayInputStream, ByteArrayOutputStream, File, StringReader, StringWriter}
import java.text.Normalizer
import javax.xml.transform._
import javax.xml.transform.stream._
import scala.io.{BufferedSource, Source}

object BulkXSLT {

  /** Convert an RDF/XML document to N-Triples */
  def rdfxml2nt(rdf:String): Array[String] = {
    val model = ModelFactory.createDefaultModel()
    val bais = new ByteArrayInputStream(rdf.getBytes("UTF-8"))
    val baos = new ByteArrayOutputStream()
    try {
      model.read(bais, null, "RDF/XML")
      model.write(baos, "N-Triples")
      val result = new String(baos.toByteArray, "UTF-8").split("\n")
      result
    } catch {
      case _: Exception =>
        Array[String]()
    } finally {
      model.close()
      baos.close()
      bais.close()
    }
  }

  /** Transform an XML document into RDF/XML using XSLT */
  def xml2rdfxml(xslTransformer:Transformer, record:String): Array[String] = {
    val xmlResultResource = new StringWriter()
    val stringReader = new StringReader(record.split('\t').last)
    val recordSource = new StreamSource(stringReader)
    val streamResult = new StreamResult(xmlResultResource)
    try {
      xslTransformer.transform(recordSource, streamResult)
      val result = xmlResultResource
        .toString
        .replaceAll("[\\r\\n]", " ")

      if (result.trim.nonEmpty)
        Array(
          if (!Normalizer.isNormalized(result, Normalizer.Form.NFC)) {
            Normalizer.normalize(result, Normalizer.Form.NFC)
          } else {
            result
          }
        )
      else
        Array[String]()
    } catch {
      case e: Exception =>
        throw e
      //                Array("<rdf:Description xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\" rdf:about=\"http://example.org/errors\"><rdfs:comment>" + e.getMessage + "</rdfs:comment><rdf:value rdf:parseType='Literal'>" + record.split('\t').last + "</rdf:value></rdf:Description>")
    } finally {
      stringReader.close()
      xmlResultResource.close()
    }
  }

  //* generalized transformer factory */
  def newTransformer(bs: BufferedSource): Transformer = {
    assert(bs != null)
//    val tf = TransformerFactory.newInstance()
    val tf = new net.sf.saxon.TransformerFactoryImpl();
    assert(tf != null)
    val streamSource = new StreamSource(bs.reader)
    assert(streamSource != null)
    tf.newTransformer(streamSource)
  }

  /** Load an XSL file into memory via classpath */
  def getXSLTransformer(resourcePath: String): Transformer = {
    val bufferedSource: BufferedSource = try {
      //		      new StreamSource(Source.fromFile(xslFile).reader())
      val classLoader = getClass.getClassLoader
      val inputStream = classLoader.getResourceAsStream(resourcePath)
      assert(inputStream != null)
      Source.fromInputStream(inputStream)
    } catch {
      case e: Throwable => throw e
    }
    newTransformer(bufferedSource)
  }

  /** Pipeline to convert a set of line-separated RDF/XML documents into N-Triples */
  def main(args: Array[String]): Unit = {
    val startTime = System.currentTimeMillis()


    val log = Logger.getLogger("BulkXSLT")
    log.setLevel(Level.ERROR)

    if (args.length != 3) {
      println("args.length=" + args.length)
      println("BulkXSLT [in] [out] [xsl]")
      System.exit(1)
    }

    val in = args(0)
    log.info("in=" + in)
    val out = args(1)
    log.info("out=" + out)
    val xslFile = args(2)
    log.info("xslFile=" + xslFile)

    val conf = new SparkConf()
      .setAppName("BulkXSLT")
      .set("spark.app.id", "BulkXSLT")

    val sc = new SparkContext(conf)
    sc.setLogLevel("WARN")

    // Set up an RDD for the XML input (one XML document per line)
    val xmlRDD = sc.textFile(in)

    // Transform the XML records to into RDF/XML
    val outRDD = xmlRDD
      .mapPartitions { lineIterator =>
        // The xslTransformer needs to be materialized on each partition, hence the .mapPartitions function

        val xslTransformer = getXSLTransformer(xslFile)

        // lineIterator contains the set of XML documents that are allocated to an individual partition
        // Use .flatMap() in case some of the input XML documents get dropped by xml2rdfxml()

        lineIterator.flatMap {
          /*
           This function processes an individual XML document, but returns an Array. The Array will normally
           contain a single RDF/XML document, but could be empty if the input XML isn't parseable.
           */

          xml2rdfxml(xslTransformer, _)
        }
      }

    //    // This output is only needed for debugging purposes
    //    outRDD
    //      .cache
    //      .saveAsTextFile(out + ".rdf")

    // Re-serialize the RDF/XML as de-duplicated N-Triples
    outRDD.flatMap {
      rdfxml2nt
    }
    .distinct
    .saveAsTextFile(out + ".nt", classOf[GzipCodec])

    // And close up shop
    sc.stop

    val endTime = System.currentTimeMillis()
    println("Elapse time: " + (endTime - startTime) / 1000.0 + "s")
    println("Thus endeth the run.")
  }
}