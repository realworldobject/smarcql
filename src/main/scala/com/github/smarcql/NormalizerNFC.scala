package com.github.smarcql

import java.text.Normalizer
import scala.io.StdIn.readLine

object NormalizerNFC {

  /** Convert characters to NFC using stdin/stdout */
  def main(args: Array[String]): Unit = {
    // Convert the text file to NFC

    var line = ""
    while ( {
      line = readLine; line != null
    }) {
      if (!Normalizer.isNormalized(line, Normalizer.Form.NFC)) {
        print(Normalizer.normalize(line, Normalizer.Form.NFC))
      } else {
        print(line)
      }
      print("\n")
    }
  }
}