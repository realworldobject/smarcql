<xsl:stylesheet
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
        xmlns:slim="http://www.loc.gov/MARC21/slim"
        xmlns:tag="https://w3id.org/smarcql/tag/"
        xmlns:position="https://w3id.org/smarcql/position/"
        xmlns:misc="https://w3id.org/smarcql/misc/"
        xmlns:code="https://w3id.org/smarcql/code/"
        xmlns:ind="https://w3id.org/smarcql/ind/"
        xmlns:owl="http://www.w3.org/2002/07/owl#"
        xmlns:skos="http://www.w3.org/2004/02/skos/core#"
        xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
        version="2.0">

    <xsl:output
            media-type="application/rdf+xml"
            method="xml"
            version="1.0"
            indent="no"
            encoding="UTF-8"/>

    <xsl:strip-space elements="*" />

    <xsl:param name="baseURI">
        <xsl:text>http://example.org/</xsl:text>
    </xsl:param>

    <xsl:template match="/">
        <rdf:RDF>
            <xsl:apply-templates />
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="slim:collection">
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="slim:record">
        <xsl:variable name="recURI">
            <xsl:value-of select="$baseURI"/>
            <xsl:value-of select="translate(slim:controlfield[@tag='001'], ' ', '')"/>
        </xsl:variable>
        <rdf:Description rdf:about="{$recURI}">
            <xsl:apply-templates>
                <xsl:with-param name="recURI" select="$recURI"/>
            </xsl:apply-templates>
        </rdf:Description>
    </xsl:template>

    <xsl:template match="slim:leader">
        <xsl:param name="recURI"/>
        <tag:bdleader>
            <rdf:Description rdf:about="{$recURI}#bdleader">
                <rdf:value>
                    <xsl:value-of select="."/>
                </rdf:value>
                <position:bdleader_05 rdf:resource="https://w3id.org/smarcql/individual/bdleader_05_{encode-for-uri(substring(., 6, 1))}"/>
                <position:bdleader_06 rdf:resource="https://w3id.org/smarcql/individual/bdleader_06_{encode-for-uri(substring(., 7, 1))}"/>
                <position:bdleader_07 rdf:resource="https://w3id.org/smarcql/individual/bdleader_07_{encode-for-uri(substring(., 8, 1))}"/>
                <position:bdleader_08 rdf:resource="https://w3id.org/smarcql/individual/bdleader_08_{encode-for-uri(substring(., 9, 1))}"/>
                <position:bdleader_09 rdf:resource="https://w3id.org/smarcql/individual/bdleader_09_{encode-for-uri(substring(., 10, 1))}"/>
                <position:bdleader_17 rdf:resource="https://w3id.org/smarcql/individual/bdleader_17_{encode-for-uri(substring(., 18, 1))}"/>
                <position:bdleader_18 rdf:resource="https://w3id.org/smarcql/individual/bdleader_18_{encode-for-uri(substring(., 19, 1))}"/>
                <position:bdleader_19 rdf:resource="https://w3id.org/smarcql/individual/bdleader_19_{encode-for-uri(substring(., 20, 1))}"/>
            </rdf:Description>
        </tag:bdleader>
    </xsl:template>

    <!-- unparseable control fields (treat as owl:DatatypeProperty) -->
    <xsl:template match="slim:controlfield[@tag='001' or @tag='003' or @tag='005']">
        <xsl:element name="tag:bd{@tag}">
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>

    <!-- parseable control field (treat as owl:ObjectProperty) -->
    <xsl:template match="slim:controlfield">
        <xsl:param name="recURI"/>
        <xsl:element name="tag:bd{@tag}">
            <rdf:Description rdf:about="{$recURI}#{@tag}--{generate-id(.)}">
                <rdf:value>
                    <xsl:value-of select="."/>
                </rdf:value>
            </rdf:Description>
        </xsl:element>
    </xsl:template>

    <xsl:template match="slim:datafield">
        <xsl:param name="recURI"/>
        <xsl:element name="tag:bd{@tag}">
            <rdf:Description rdf:about="{$recURI}#{@tag}--{generate-id(.)}">
                <xsl:apply-templates select="." mode="rdfs:label"/>

                <xsl:apply-templates select="*|@*">
                    <xsl:with-param name="recURI" select="$recURI"/>
                    <xsl:with-param name="tag" select="@tag"/>
                </xsl:apply-templates>
            </rdf:Description>
        </xsl:element>
    </xsl:template>

    <!-- The tag is already encoded in the RDF as a property -->
    <xsl:template match="@tag"/>

    <!-- Treat the indicators as owl:ObjectProperty links to pre-defined concepts in the SMARCQL ontology -->
    <xsl:template match="@ind1|@ind2">
        <xsl:param name="recURI"/>
        <xsl:param name="tag"/>

        <xsl:element name="ind:bd{$tag}_{local-name()}">
            <xsl:attribute name="rdf:resource">
                <xsl:text>https://w3id.org/smarcql/individual/bd</xsl:text>
                <xsl:value-of select="$tag"/>
                <xsl:text>_</xsl:text>
                <xsl:value-of select="local-name()"/>
                <xsl:text>_</xsl:text>
                <xsl:value-of select="encode-for-uri(.)"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="slim:subfield">
        <xsl:param name="recURI"/>

        <xsl:element name="code:s{@code}">
            <xsl:value-of select="."/>
        </xsl:element>

        <xsl:if test="@code='6'">
            <xsl:variable name="linkingTag">
                <xsl:value-of select="substring-before(., '-')"/>
            </xsl:variable>
            <xsl:variable name="occurrenceNumber">
                <xsl:choose>
                    <xsl:when test="contains(., '/')">
                        <xsl:value-of select="substring-before(substring-after(., '-'), '/')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring-after(., '-')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!--
        <xsl:variable name="id">
            <xsl:value-of select="generate-id(..)"/>
        </xsl:variable>
        <xsl:variable name="currentTag">
            <xsl:value-of select="../@tag"/>
        </xsl:variable>
        <xsl:variable name="currentTags" as="node()*">
            <xsl:copy-of select="../../slim:datafield[@tag=$currentTag]"/>
        </xsl:variable>
        <xsl:variable name="position">
            <xsl:text>find? </xsl:text>
            <xsl:value-of select="$id"/>
            <xsl:text>  </xsl:text>
            <xsl:for-each select="$currentTags">
                    <xsl:value-of select="generate-id()"/>
                <xsl:text>-</xsl:text>
            </xsl:for-each>
        </xsl:variable>

        <xsl:message>
            <xsl:text>position: </xsl:text>
            <xsl:value-of select="$position"/>
            <xsl:text>    </xsl:text>
            <xsl:text>foo:</xsl:text>
            <xsl:value-of select="count($currentTags)"/>
            <xsl:text>   </xsl:text>
            <xsl:for-each select="$currentTags">
                <xsl:value-of select="."/>
            </xsl:for-each>
        </xsl:message>

        <xsl:message>
            <xsl:text>id: </xsl:text>
            <xsl:value-of select="$id"/>
            <xsl:text>   </xsl:text>
            <xsl:text>position: </xsl:text>
            <xsl:value-of select="../../slim:datafield[generate-id() = $id]"/>
        </xsl:message>
        -->

        <code:s6_linkingTag rdf:resource="https://w3id.org/smarcql/tag/bd{$linkingTag}"/>

        <xsl:if test="$occurrenceNumber != '00'">
            <xsl:variable name="lookup" select="concat(../@tag, substring(., 4, 3))"/>
            <xsl:variable name="linkingField" select="../../slim:datafield[@tag=$linkingTag and starts-with(slim:subfield[@code='6'], $lookup)]"/>
            <xsl:choose>
                <xsl:when test="count($linkingField) &gt; 1">
                    <xsl:message terminate="no">
                        <xsl:text>Multiple hits on linking field! :</xsl:text>
                        <xsl:value-of select="$recURI"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$lookup"/>
                    </xsl:message>
                </xsl:when>
                <xsl:when test="$linkingField">
                    <skos:exactMatch rdf:resource="{$recURI}#{$linkingTag}--{generate-id($linkingField)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>Linking field not found: </xsl:text>
                        <xsl:value-of select="$recURI"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="."/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>

        <xsl:if test="string-length(.) - string-length(translate(., '/', ''))=1">
            <code:s6_scriptIdentificationCode rdf:resource="https://w3id.org/smarcql/individual/s6_scriptIdentificationCode_{encode-for-uri(substring-after(., '/'))}"/>
        </xsl:if>
        <xsl:if test="string-length(.) - string-length(translate(., '/', ''))=2">
            <code:s6_scriptIdentificationCode rdf:resource="https://w3id.org/smarcql/individual/s6_scriptIdentificationCode_{encode-for-uri(substring-before(substring-after(., '/'), '/'))}"/>
            <code:s6_orientationCode rdf:resource="https://w3id.org/smarcql/individual/s6_orientation_code_{encode-for-uri(substring-after(substring-after(., '/'), '/'))}"/>
        </xsl:if>
    </xsl:if>
</xsl:template>

<xsl:template match="*" mode="rdfs:label">
    <rdfs:label>
        <xsl:for-each select="*">
            <xsl:if test="position() &gt; 1">
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:text>≠</xsl:text>
            <xsl:value-of select="@code"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="."/>
        </xsl:for-each>
    </rdfs:label>
</xsl:template>

<xsl:template match="*|@*">
    <xsl:message>
        <xsl:text>Missing stuff...</xsl:text>
        <xsl:copy-of select="."/>
    </xsl:message>
</xsl:template>
</xsl:stylesheet>