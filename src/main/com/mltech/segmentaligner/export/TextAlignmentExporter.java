package com.mltech.segmentaligner.export;


import com.mltech.laf.annotations.Alignment;
import com.mltech.laf.document.BitextDocument;
import com.mltech.laf.document.IDocument;
import com.mltech.laf.exporter.IDocumentExporter;


public final class TextAlignmentExporter implements IDocumentExporter {
	public String export(IDocument document) {
		BitextDocument bitextDocument = (BitextDocument) document; 
		String result = "";
		for (Alignment alignment : bitextDocument.alignment("segment")) {
			if (alignment.list1().size() > 0) result += bitextDocument.document1().text().substring(alignment.list1().get(0).start(), alignment.list1().get(alignment.list1().size() - 1).end()) + "\n";
			if (alignment.list2().size() > 0) result += bitextDocument.document2().text().substring(alignment.list2().get(0).start(), alignment.list2().get(alignment.list2().size() - 1).end()) + "\n";
			result += "\n";
		}
		return result;
	}
}
