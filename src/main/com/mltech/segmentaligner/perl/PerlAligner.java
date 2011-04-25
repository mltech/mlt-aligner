package com.mltech.segmentaligner.perl;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import com.mltech.laf.annotations.Alignment;
import com.mltech.laf.annotations.Annotation;
import com.mltech.laf.annotations.AnnotationSet;
import com.mltech.laf.annotations.FeatureSet;
import com.mltech.laf.document.BitextDocument;
import com.mltech.laf.document.Document;
import com.mltech.laf.parser.BitextDocumentParser;
import com.mltech.segmentaligner.AlignerException;
import com.mltech.segmentaligner.champollion.scoring.IAlignmentScoreNormalizingMethod;
import com.mltech.segmentaligner.filter.AlignmentFilterException;
import com.mltech.utils.Command;
import com.mltech.utils.CommandException;
import com.mltech.utils.Utils;


public class PerlAligner extends BitextDocumentParser {
	private Command _alignerCommand;

	private String _usedict;
	private String _dictpath;
	private String _stoplistpath;
	private String _xtoyc;
	private String _penalty01;
	private String _penalty21;
	private String _penalty12;
	private String _penalty22;
	private String _penalty31;
	private String _penalty13;
	private String _penalty32;
	private String _penalty23;
	private String _penalty41;
	private String _penalty14;
	
	private IAlignmentScoreNormalizingMethod _scoringmethod;
	private HashMap<String, IAlignmentScoreNormalizingMethod> _scoringmethods;

	public void setUsedict(String usedict) {
		_usedict = usedict;
	}

	public void setDictpath(String dictpath) {
		_dictpath = dictpath;
	}

	public void setStoplistpath(String stoplistpath) {
		_stoplistpath = stoplistpath;
	}

	public void setXtoyc(String xtoyc) {
		_xtoyc = xtoyc;
	}

	public void setPenalty01(String penalty01) {
		_penalty01 = penalty01;
	}

	public void setPenalty21(String penalty21) {
		_penalty21 = penalty21;
	}

	public void setPenalty12(String penalty12) {
		_penalty12 = penalty12;
	}

	public void setPenalty22(String penalty22) {
		_penalty22 = penalty22;
	}

	public void setPenalty31(String penalty31) {
		_penalty31 = penalty31;
	}

	public void setPenalty13(String penalty13) {
		_penalty13 = penalty13;
	}

	public void setPenalty32(String penalty32) {
		_penalty32 = penalty32;
	}

	public void setPenalty23(String penalty23) {
		_penalty23 = penalty23;
	}

	public void setPenalty41(String penalty41) {
		_penalty41 = penalty41;
	}

	public void setPenalty14(String penalty14) {
		_penalty14 = penalty14;
	}

	public void setScoringmethod(String method) {
		if (_scoringmethods.containsKey(method)) {
			_scoringmethod = _scoringmethods.get(method);
		} else {
			// TODO: StringUtils.join _methods , ", "
			throw new AlignmentFilterException("The normalising method " + method + "does not exist. It should be part of {" + "}");
		}
	}
	
	public PerlAligner() {
		_scoringmethods = new HashMap<String, IAlignmentScoreNormalizingMethod>();
		_scoringmethods.put("watgt", new WordAvgTgt());
		_scoringmethods.put("wasrc", new WordAvgSrc());
		_scoringmethods.put("wamin", new WordAvgMinSrcTgt());
		_scoringmethods.put("wamax", new WordAvgMaxSrcTgt());
		_scoringmethods.put("wamean", new WordAvgMeanSrcTgt());
	}
	
	private String toTokenString(Document document) {
		StringBuilder sb = new StringBuilder();
		for (Annotation segment : document.annotations("segment")) {
			for (Annotation token : document.subAnnotationSet(segment, "token")) {
				sb.append(token.feature("string"));
				sb.append("|");
			}
			sb.deleteCharAt(sb.length() - 1);
			sb.append("<br/>");
		}
		return sb.toString();
	}

	@Override
	protected void parse(BitextDocument bitextDocument) {
		// TODO: in the configuration file of the plugin
		if (bitextDocument.document1().annotations("token").size() == 0)
			throw new AlignerException(
					"Document 1 must contain token annotations");
		if (bitextDocument.document1().annotations("segment").size() == 0)
			throw new AlignerException(
					"Document 1 must contain segment annotations");
		if (bitextDocument.document1().annotations("token").size() == 0)
			throw new AlignerException(
					"Document 2 must contain token annotations");
		if (bitextDocument.document1().annotations("segment").size() == 0)
			throw new AlignerException(
					"Document 2 must contain segment annotations");

		String text1 = toTokenString(bitextDocument.document1());
		String text2 = toTokenString(bitextDocument.document2());

		try {
			// TODO: cleanup of the pipes in text -> separate module cleanup +
			// de-cleanup
			String bitext = text1 + "||||" + text2;
			System.err.println(bitext);
			String alignmentString = _alignerCommand.exec(bitext);
			System.err.println(alignmentString);

			AnnotationSet segments1 = bitextDocument.document1().annotations("segment");
			AnnotationSet segments2 = bitextDocument.document2().annotations("segment");
			List<Alignment> alignments = bitextDocument.alignment("segment");

			double oldScore = 0;
			double score = 0;

			for (String line : alignmentString.split("\n")) {
				try {
					AnnotationSet annotationList1 = new AnnotationSet();
					AnnotationSet annotationList2 = new AnnotationSet();
					String tmp[] = line.split("\t");

					score = Double.parseDouble(tmp[1]) - oldScore;
					oldScore = Double.parseDouble(tmp[1]);

					tmp = tmp[0].split(" <=> ");
					double nbw1 = 0;
					double nbw2 = 0;
					for (String seg1 : tmp[0].split(",")) {
						if (!seg1.equals("omitted")) {
							Annotation a = segments1.get(Integer.parseInt(seg1) - 1);
							annotationList1.add(a);
							nbw1 += bitextDocument.document1().subAnnotationSet(a, "token").size();
						}
					}
					for (String seg2 : tmp[1].split(",")) {
						if (!seg2.equals("omitted")) {
							Annotation a = segments2.get(Integer.parseInt(seg2) - 1);
							annotationList2.add(a);
							nbw2 += bitextDocument.document2().subAnnotationSet(a, "token").size();
						}
					}

					FeatureSet features = new FeatureSet();
					features.put("score", String.valueOf(score * _scoringmethod.score(nbw1, nbw2)));
					alignments.add(new Alignment(annotationList1, annotationList2, features));
				} catch (Exception e) {
					System.err.println("Error in alignment: ");
					e.printStackTrace(System.err);
				}
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		System.out.println(" ++> " + bitextDocument.alignment("segment").size());
	}

	@Override
	protected void init() {
		try {
			_alignerCommand = new Command("perl", "-I", Utils.cwd()
					+ "/ext/perl", Utils.cwd() + "/ext/perl/align.pl",
					"usedict", _usedict, "dictpath", _dictpath, "stoplistpath",
					_stoplistpath, "xtoyc", _xtoyc, "penalty01", _penalty01,
					"penalty21", _penalty21, "penalty12", _penalty12,
					"penalty22", _penalty22, "penalty31", _penalty31,
					"penalty13", _penalty13, "penalty32", _penalty32,
					"penalty23", _penalty23, "penalty41", _penalty41,
					"penalty14", _penalty14);
		} catch (CommandException e) {
			e.printStackTrace();
		}
	}
	
	private class WordAvgTgt implements IAlignmentScoreNormalizingMethod {
		public double score(double nbw1, double nbw2) {
			return 1 / (nbw2 + 1);
		}
	}

	private class WordAvgSrc implements IAlignmentScoreNormalizingMethod {
		public double score(double nbw1, double nbw2) {
			return 1 / (nbw1 + 1);
		}
	}

	private class WordAvgMinSrcTgt implements IAlignmentScoreNormalizingMethod {
		public double score(double nbw1, double nbw2) {
			return 1 / (Math.min(nbw1, nbw2) + 1);
		}
	}

	private class WordAvgMaxSrcTgt implements IAlignmentScoreNormalizingMethod {
		public double score(double nbw1, double nbw2) {
			return 1 / (Math.max(nbw1, nbw2) + 1);
		}
	}

	private class WordAvgMeanSrcTgt implements IAlignmentScoreNormalizingMethod {
		public double score(double nbw1, double nbw2) {
			return 1 / ((nbw1 + nbw2) / 2 + 1);
		}
	}
}
