package com.mltech.segmentaligner.champollion;

import java.util.ArrayList;
import java.util.HashMap;

import com.mltech.laf.annotations.Annotation;
import com.mltech.laf.document.Document;


public class TokenStats extends HashMap<String, Integer> {
	private static final long serialVersionUID = -1004084098954134405L;
	private int _totalTokens;
	private ArrayList<Integer> _segmentLengths; // segment length without white spaces

	public int getTotalTokens() {
		return _totalTokens;
	}

	public ArrayList<Integer> getSegmentLengths() {
		return _segmentLengths;
	}

	public TokenStats(Document document) {
		this(document, null);
	}

	public TokenStats(Document document, StopWords stopWords) {
		_segmentLengths = new ArrayList<Integer>();

		int segmentNo = 0;
		for (Annotation segment : document.annotations("segment")) {
			int sntLen = 0;
			for (Annotation token : document.subAnnotationSet(segment, "token")) {
				String tokenString = token.feature("string");
				sntLen += tokenString.length(); // TODO: the number of tokens per sentence is more interesting ???
				if (stopWords == null || !stopWords.contains(tokenString)) {
					Integer tokCnt = this.get(tokenString);
					this.put(tokenString, tokCnt == null ? 1 : tokCnt + 1);
					_totalTokens++;
				}
			}

			_segmentLengths.add(sntLen);
			segmentNo++;
		}
		System.out.println("Done.");
		System.out.println("Number of segments: " + segmentNo);
	}
}
