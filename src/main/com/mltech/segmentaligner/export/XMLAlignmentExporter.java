package com.mltech.segmentaligner.export;

import com.mltech.laf.annotations.Alignment;
import com.mltech.laf.document.BitextDocument;
import com.mltech.laf.document.IDocument;
import com.mltech.laf.exporter.IDocumentExporter;


public final class XMLAlignmentExporter implements IDocumentExporter {
	public String export(IDocument document) {
		BitextDocument bitextDocument = (BitextDocument) document;
		// TODO: add xml header
		String result = "<part name=\"\">\n" +
				" <alignments>\n";
		int id = 0;
		
		System.out.println(" ==> " + bitextDocument.alignment("segment").size());
//		System.out.println(bitextDocument.document1().text());
		
		for (Alignment alignment : bitextDocument.alignment("segment")) {
			result += "  <alignment id=\"" + ++id + "\" score=\"" + alignment.feature("score") + "\">\n";
			if (alignment.list1().size() > 0) {
// TODO: implement white space annotation and take normalized value only if not whitespace
// TODO: output normalized version
// TODO: OR: implement "text" annotation with string='whole text' -> norm='whole text normalized' 
//				for (Annotation segment: alignment.list1()) {
//					for (Annotation token : bitextDocument.document1().subAnnotationSet(segment, "token")) {
//						
//					}
//			}
				result += "   <segment lang=\"1\">"
						+ bitextDocument.document1().text().substring(alignment.list1().get(0).start(), alignment.list1().get(alignment.list1().size() - 1).end())
						+ "</segment>\n";
			}
			if (alignment.list2().size() > 0) {
				result += "   <segment lang=\"2\">"
						+ bitextDocument.document2().text().substring(alignment.list2().get(0).start(), alignment.list2().get(alignment.list2().size() - 1).end())
						+ "</segment>\n";
			}
			result += "  </alignment>\n";
		}
		result += " </alignments>\n" +
				"</part>";
		return result;
	}
}
