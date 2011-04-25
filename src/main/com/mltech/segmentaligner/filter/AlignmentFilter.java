package com.mltech.segmentaligner.filter;

import java.util.ArrayList;
import java.util.List;

import com.mltech.laf.annotations.Alignment;
import com.mltech.laf.document.BitextDocument;
import com.mltech.laf.document.IDocument;
import com.mltech.laf.filter.AFilter;


public class AlignmentFilter extends AFilter {
	private double _threshold;

	public AlignmentFilter() {

	}

	public void setThreshold(String threshold) {
		try {
			_threshold = Double.parseDouble(threshold);
		} catch (NumberFormatException e) {
			throw new AlignmentFilterException("threshold must be a float");
		}
	}

	public void filter(IDocument document) {
		BitextDocument bitextDocument = (BitextDocument) document;
		List<Alignment> oldAlignments = (ArrayList<Alignment>) ((ArrayList<Alignment>) bitextDocument.alignment("segment")).clone();
		List<Alignment> alignments = bitextDocument.alignment("segment");
		bitextDocument.alignment("segment").clear();
		for (Alignment alignment : oldAlignments) {
			if (Double.parseDouble(alignment.feature("score")) >= _threshold) {
				alignments.add(alignment);
			}
		}
	}

	@Override
	protected void init() {
	}
}
