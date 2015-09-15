<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xhref" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:exsl="http://exslt.org/common" xmlns:doc="http://xsltsl.org/xsl/documentation/1.0"
    xmlns:dt="http://xsltsl.org/date-time" xmlns:str="http://xsltsl.org/string"
    xmlns:node="http://xsltsl.org/node" xmlns:markup="http://xsltsl.org/markup"
    xmlns:uri="http://xsltsl.org/uri" exclude-result-prefixes="xs xml xlink"
    extension-element-prefixes="xs xsl exsl doc dt str uri node markup xlink" version="1.0">

    <xsl:output method="html" indent="yes"/>

    <xsl:variable name="json-ld.context.path" select="'http://schema.org/'"/>

    <xsl:template match="*" mode="json-ld">
        <xsl:choose>
            <xsl:when test="@itemtype or @itemprop">
                <xsl:apply-templates select="." mode="json-ld-array"/>
            </xsl:when>
            <xsl:when
                test="child::*[@itemtype or @itemprop] and following-sibling::*[descendant-or-self::*[@itemtype or @itemprop]]">
                <xsl:apply-templates select="*" mode="json-ld"/>
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="*" mode="json-ld"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*" mode="json-ld-array">
        <xsl:choose>
            <xsl:when
                test="name(preceding-sibling::*[1]) = name(current()) and name(following-sibling::*[1]) != name(current())">
                <xsl:apply-templates select="." mode="json-ld-object"/>
                <xsl:text>]</xsl:text>
                <xsl:if test="count(following-sibling::*[name() != name(current())]) > 0">,
                </xsl:if>
            </xsl:when>
            <xsl:when test="name(preceding-sibling::*[1]) = name(current())">
                <xsl:apply-templates select="." mode="json-ld-object"/>
                <xsl:if test="name(following-sibling::*) = name(current())">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:when>
            <xsl:when test="following-sibling::*[1][name() = name(current())]">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>" : [</xsl:text>
                <xsl:apply-templates select="." mode="json-ld-object"/>
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:when test="count(./child::*) > 0 or count(@itemtype) > 0">
                <xsl:if test="@itemprop">
                    <xsl:value-of select="concat('&quot;', @itemprop, '&quot;: ')"/>
                </xsl:if>
                <xsl:apply-templates select="." mode="json-ld-object"/>
                <xsl:if test="count(following-sibling::*) > 0">, </xsl:if>
            </xsl:when>
            <xsl:when test="count(./child::*) = 0">
                <xsl:apply-templates select="." mode="json-ld-node"/>
                <xsl:if test="count(following-sibling::*) > 0">, </xsl:if>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*" mode="json-ld-object">
        <xsl:text>{</xsl:text>
        <xsl:if test="@itemtype">
            <xsl:value-of
                select="concat('&quot;@type&quot;: &quot;', $json-ld.context.path, @itemtype, '&quot;')"/>
            <xsl:if test="count(child::*) > 0 or text()">, </xsl:if>
        </xsl:if>
        <xsl:apply-templates select="./*" mode="json-ld"/>
        <xsl:if test="count(child::*) = 0 and text() and not(@itemprop)"> </xsl:if>
        <xsl:if test="count(child::*) = 0 and text() and @itemprop">
            <xsl:value-of select="concat('&quot;', @itemprop, '&quot;: &quot;', text(), '&quot;')"/>
        </xsl:if>
        <xsl:text>}</xsl:text>
        <xsl:if test="position() &lt; last()">, </xsl:if>
    </xsl:template>

    <xsl:template match="*" mode="json-ld-node">
        <xsl:if test="@itemtype">
            <xsl:value-of
                select="concat('&quot;@type&quot;: &quot;', $json-ld.context.path, @itemtype, '&quot;')"/>
            <xsl:if test="count(child::*) > 0 or text()">, </xsl:if>
        </xsl:if>
        <xsl:apply-templates select="./*" mode="json-ld"/>
        <xsl:choose>
            <xsl:when test="count(child::*) = 0 and not(@itemprop)"/>
            <xsl:when test="count(child::*) = 0 and @itemprop and @datetime">
                <xsl:value-of
                    select="concat('&quot;', @itemprop, '&quot;: &quot;', @datetime, '&quot;')"/>
            </xsl:when>
            <xsl:when test="count(child::*) = 0 and @itemprop and @content">
                <xsl:value-of
                    select="concat('&quot;', @itemprop, '&quot;: &quot;', @content, '&quot;')"/>
            </xsl:when>
            <xsl:when test="count(child::*) = 0 and text() and @itemprop">
                <xsl:value-of
                    select="concat('&quot;', @itemprop, '&quot;: &quot;', text(), '&quot;')"/>
            </xsl:when>
        </xsl:choose>
        <xsl:if test="position() &lt; last()">, </xsl:if>
    </xsl:template>


</xsl:stylesheet>