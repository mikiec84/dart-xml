library xml_events.converters.event_decoder;

import 'dart:convert'
    show Converter, StringConversionSink, StringConversionSinkBase;

import 'package:petitparser/petitparser.dart' show Parser, Result, Success;

import '../../../xml.dart' show XmlParserException;
import '../../xml/entities/default_mapping.dart';
import '../../xml/entities/entity_mapping.dart';
import '../event.dart';
import '../iterable.dart';
import '../parser.dart';

/// A converter that decodes a [String] to a sequence of [XmlEvent] objects.
class XmlEventDecoder extends Converter<String, List<XmlEvent>> {
  final XmlEntityMapping entityMapping;

  const XmlEventDecoder(
      {this.entityMapping = const XmlDefaultEntityMapping.xml()});

  @override
  List<XmlEvent> convert(String input, [int start = 0, int end]) {
    end = RangeError.checkValidRange(start, end, input.length);
    return XmlEventIterable(input.substring(start, end), entityMapping)
        .toList(growable: false);
  }

  @override
  StringConversionSink startChunkedConversion(Sink<List<XmlEvent>> sink) =>
      _XmlEventDecoderSink(sink, entityMapping);
}

class _XmlEventDecoderSink extends StringConversionSinkBase {
  _XmlEventDecoderSink(this.sink, XmlEntityMapping entityMapping)
      : eventParser = eventParserCache[entityMapping];

  final Sink<List<XmlEvent>> sink;
  final Parser eventParser;

  String carry = '';

  @override
  void addSlice(String str, int start, int end, bool isLast) {
    end = RangeError.checkValidRange(start, end, str.length);
    if (start == end) {
      return;
    }
    final result = <XmlEvent>[];
    Result previous = Success(carry + str.substring(start, end), 0, null);
    for (;;) {
      final current = eventParser.parseOn(previous);
      if (current.isSuccess) {
        result.add(current.value);
        previous = current;
      } else {
        carry = previous.buffer.substring(previous.position);
        break;
      }
    }
    if (result.isNotEmpty) {
      sink.add(result);
    }
    if (isLast) {
      close();
    }
  }

  @override
  void close() {
    if (carry.isNotEmpty) {
      throw XmlParserException('Unable to parse remaining input: $carry');
    }
    sink.close();
  }
}
