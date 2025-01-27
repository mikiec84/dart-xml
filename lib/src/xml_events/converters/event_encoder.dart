library xml_events.converters.event_encoder;

import 'dart:convert' show Converter, ChunkedConversionSink;

import 'package:convert/convert.dart' show StringAccumulatorSink;

import '../../xml/entities/default_mapping.dart';
import '../../xml/entities/entity_mapping.dart';
import '../../xml/utils/token.dart';
import '../event.dart';
import '../events/cdata_event.dart';
import '../events/comment_event.dart';
import '../events/doctype_event.dart';
import '../events/end_element_event.dart';
import '../events/processing_event.dart';
import '../events/start_element_event.dart';
import '../events/text_event.dart';
import '../visitor.dart';

/// A converter that encodes a sequence of [XmlEvent] objects to a [String].
class XmlEventEncoder extends Converter<List<XmlEvent>, String> {
  final XmlEntityMapping entityMapping;

  const XmlEventEncoder(
      {this.entityMapping = const XmlDefaultEntityMapping.xml()});

  @override
  String convert(List<XmlEvent> input) {
    final accumulator = StringAccumulatorSink();
    final conversion = startChunkedConversion(accumulator);
    conversion.add(input);
    conversion.close();
    return accumulator.string;
  }

  @override
  ChunkedConversionSink<List<XmlEvent>> startChunkedConversion(
          Sink<String> sink) =>
      _XmlEventEncoderSink(sink, entityMapping);
}

class _XmlEventEncoderSink extends ChunkedConversionSink<List<XmlEvent>>
    with XmlEventVisitor {
  _XmlEventEncoderSink(this.sink, this.entityMapping);

  final Sink<String> sink;
  final XmlEntityMapping entityMapping;

  @override
  void add(List<XmlEvent> chunk) => chunk.forEach(visit);

  @override
  void close() => sink.close();

  @override
  void visitCDATAEvent(XmlCDATAEvent event) {
    sink.add(XmlToken.openCDATA);
    sink.add(event.text);
    sink.add(XmlToken.closeCDATA);
  }

  @override
  void visitCommentEvent(XmlCommentEvent event) {
    sink.add(XmlToken.openComment);
    sink.add(event.text);
    sink.add(XmlToken.closeComment);
  }

  @override
  void visitDoctypeEvent(XmlDoctypeEvent event) {
    sink.add(XmlToken.openDoctype);
    sink.add(XmlToken.whitespace);
    sink.add(event.text);
    sink.add(XmlToken.closeDoctype);
  }

  @override
  void visitEndElementEvent(XmlEndElementEvent event) {
    sink.add(XmlToken.openEndElement);
    sink.add(event.name);
    sink.add(XmlToken.closeElement);
  }

  @override
  void visitProcessingEvent(XmlProcessingEvent event) {
    sink.add(XmlToken.openProcessing);
    sink.add(event.target);
    if (event.text.isNotEmpty) {
      sink.add(XmlToken.whitespace);
      sink.add(event.text);
    }
    sink.add(XmlToken.closeProcessing);
  }

  @override
  void visitStartElementEvent(XmlStartElementEvent event) {
    sink.add(XmlToken.openElement);
    sink.add(event.name);
    for (final attribute in event.attributes) {
      sink.add(XmlToken.whitespace);
      sink.add(attribute.name);
      sink.add(XmlToken.equals);
      sink.add(entityMapping.encodeXmlAttributeValueWithQuotes(
        attribute.value,
        attribute.attributeType,
      ));
    }
    if (event.isSelfClosing) {
      sink.add(XmlToken.closeEndElement);
    } else {
      sink.add(XmlToken.closeElement);
    }
  }

  @override
  void visitTextEvent(XmlTextEvent event) {
    sink.add(entityMapping.encodeXmlText(event.text));
  }
}
