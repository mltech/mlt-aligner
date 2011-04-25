package com.mltech.segmentaligner.champollion;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map.Entry;

import com.mltech.laf.annotations.Alignment;
import com.mltech.laf.annotations.Annotation;
import com.mltech.laf.annotations.AnnotationSet;
import com.mltech.laf.annotations.FeatureSet;
import com.mltech.laf.document.BitextDocument;
import com.mltech.laf.document.Document;
import com.mltech.laf.parser.BitextDocumentParser;
import com.mltech.segmentaligner.AlignerException;
import com.mltech.segmentaligner.champollion.scoring.IAlignmentScoreNormalizingMethod;
import com.mltech.segmentaligner.champollion.scoring.ScoringMethod;


/**
 * Java implementation of the Champollion aligner (http://champollion.sourceforge.net/)
 * working over annotations
 * @author sdruon
 *
 */
public class Aligner extends BitextDocumentParser {
	private String _usedict;
	private String _dictpath;
	private String _stoplistpath;
	private double _xtoyc;

	private TokenStats _documentTokenStat1;
	private TokenStats _documentTokenStat2;
	ArrayList<HashMap<String, Integer>> _tokenSegmentStat1;
	ArrayList<HashMap<String, Integer>> _tokenSegmentStat2;
	private String _lemmaFeature1;
	private String _lemmaFeature2;

	// TODO: externalize to config file
	private static int WIN_PER_100 = 8;
	private static int MIN_WIN_SIZE = 10;
	private static int MAX_WIN_SIZE = 600;

	private static double MIN_SCORE = -10;

	private static AnnotationSet EMPTY_ALIGNMENT = new AnnotationSet();

	private Dictionary _dictionary;
	private StopWords _xStopWords; // TODO: rename all x and y to 0 and 1
	private StopWords _yStopWords; // TODO: implement

	private BitextDocument _bitextDocument;
	private AnnotationSet _segments1;
	private AnnotationSet _segments2;
	private List<Alignment> _alignments;

	private double[][] _score; // TODO: to be removed

	private double[][] _penalty = new double[5][5]; // TODO: rewrite in base 0

	// TODO: from config
	private IAlignmentScoreNormalizingMethod _scoringMethod;

	/**
	 * sets scoring method
	 * @param scoringmethod scoring merhod to be used: values in the list watgt, wasrc, wamin, wamax, wamean (cf. @see com.mltech.segmentaligner.champollion.scoring.ScoringMethod)
	 */
	public void setScoringmethod(String scoringmethod) {
		_scoringMethod = ScoringMethod.valueOf(scoringmethod.toUpperCase()).method();
	}

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
		_xtoyc = Double.parseDouble(xtoyc);
	}

	public void setPenalty21(String penalty21) {
		_penalty[2][1] = Double.parseDouble(penalty21);
	}

	public void setPenalty12(String penalty12) {
		_penalty[1][2] = Double.parseDouble(penalty12);
	}

	public void setPenalty22(String penalty22) {
		_penalty[2][2] = Double.parseDouble(penalty22);
	}

	public void setPenalty31(String penalty31) {
		_penalty[3][1] = Double.parseDouble(penalty31);
	}

	public void setPenalty13(String penalty13) {
		_penalty[1][3] = Double.parseDouble(penalty13);
	}

	public void setPenalty32(String penalty32) {
		_penalty[3][2] = Double.parseDouble(penalty32);
	}

	public void setPenalty23(String penalty23) {
		_penalty[2][3] = Double.parseDouble(penalty23);
	}

	public void setPenalty41(String penalty41) {
		_penalty[4][1] = Double.parseDouble(penalty41);
	}

	public void setPenalty14(String penalty14) {
		_penalty[1][4] = Double.parseDouble(penalty14);
	}

	/**
	 * Aligns a bitext document: annotates it with alignment information
	 * @param bitextDocument
	 */
	public void align(BitextDocument bitextDocument) {
		_bitextDocument = bitextDocument;

		_segments1 = _bitextDocument.document1().annotations("segment");
		_segments2 = _bitextDocument.document2().annotations("segment");
		_alignments = _bitextDocument.alignment("segment");

		// TODO:
		// - remove punctuation from the alignment?
		// - prioritise measurements for example?

		System.out.println("Aligning...");

		_documentTokenStat1 = new TokenStats(bitextDocument.document1());
		_documentTokenStat2 = new TokenStats(bitextDocument.document2());

		_tokenSegmentStat1 = setDocumentTokenStats(bitextDocument.document1(), _lemmaFeature1);
		_tokenSegmentStat2 = setDocumentTokenStats(bitextDocument.document2(), _lemmaFeature2);

		int nx = bitextDocument.document1().annotations("segment").size();
		int ny = bitextDocument.document2().annotations("segment").size();

		double xyratio = (double) nx / ny;
		int w1Size = (int) Math.floor(xyratio * nx * WIN_PER_100 / 100);
		int w2Size = (int) Math.floor((double) Math.abs(nx - ny) * 3 / 4);
		int windowSize = Math.min(Math.max(MIN_WIN_SIZE, Math.max(w1Size, w2Size)), MAX_WIN_SIZE);

		int[][] xPath = new int[nx + 1][ny + 1]; // TODO: indexes should start a 1 -> fix
		int[][] yPath = new int[nx + 1][ny + 1]; // TODO: indexes should start a 1 -> fix

		_score = new double[nx + 1][ny + 1];
		for (int j = 0; j <= ny; j++) {
			int center = (int) Math.floor(j * xyratio);
			int window_start = center - windowSize > 0 ? center - windowSize : 0;
			int window_end = center + windowSize < nx ? center + windowSize : nx;

			double maxScore = 0; // TODO: move to loop -> double maxScore = MIN_SCORE

			for (int i = window_start; i <= window_end; i++) {
				String scoreString = "";
				AlignmentPair maxAP = null;
				maxScore = MIN_SCORE;
				for (AlignmentPair ap : AlignmentPair.values()) {
					double score = i >= ap.segment1() && j >= ap.segment2() ?
							getScore(i - ap.segment1(), j - ap.segment2()) +
									calculateSpanAlignmentScore(bitextDocument,
											ap.segment1() > 0 ? i - ap.segment1() : -1,
											ap.segment1() > 0 ? i - 1 : -1,
											ap.segment2() > 0 ? j - ap.segment2() : -1,
											ap.segment2() > 0 ? j - 1 : -1)
							: MIN_SCORE;
					// TODO: too many conditions, rewrite

					if (score > maxScore) {
						maxScore = score;
						maxAP = ap;
					}
					scoreString += score + ":";
				}

				if (maxScore == MIN_SCORE) {
					setScore(i, j, 0);
				} else {
					setScore(i, j, maxScore);
					xPath[i][j] = i - maxAP.segment1();
					yPath[i][j] = j - maxAP.segment2();
				}
			}
		}

		int oi = -1; // ??
		int oj = -1; // ??
		for (int i = nx, j = ny; i > 0 || j > 0; i = oi, j = oj) {
			oi = xPath[i][j];
			oj = yPath[i][j];

			alignSegments(oi, i - 1, oj, j - 1, getScore(i, j) - getScore(xPath[i][j], yPath[i][j])); // TODO:
			// indexes
		}
	}

	private ArrayList<HashMap<String, Integer>> setDocumentTokenStats(Document document, String lemmaFeature) {
		ArrayList<HashMap<String, Integer>> tokenSegmentStat = new ArrayList<HashMap<String, Integer>>();
		for (Annotation segment : document.annotations("segment")) {
			HashMap<String, Integer> stat = new HashMap<String, Integer>();
			for (Annotation token : document.subAnnotationSet(segment, "token")) {
				int cnt = stat.get(token.feature(lemmaFeature)) != null ? stat.get(token.feature(lemmaFeature)) + 1 : 1;
				stat.put((String) token.feature(lemmaFeature), cnt);
			}
			tokenSegmentStat.add(stat);
		}
		return tokenSegmentStat;
	}

	/**
	 * Calculate alignment scores
	 * @param xStartSegment start segement to align in document1
	 * @param xEndSegment end segement to align in document1
	 * @param yStartSegment start segement to align in document2
	 * @param yEndSegment end segement to align in document2
	 * @param score
	 */
	private void alignSegments(int xStartSegment, int xEndSegment, int yStartSegment, int yEndSegment, double score) {
		List<Annotation> list1 = getAnnotationList(_segments1, xStartSegment, xEndSegment);
		List<Annotation> list2 = getAnnotationList(_segments2, yStartSegment, yEndSegment);

		double nbw1 = 0;
		double nbw2 = 0;
		for (Annotation seg : list1) {
			nbw1 += _bitextDocument.document1().subAnnotationSet(seg, "token").size();
		}
		for (Annotation seg : list2) {
			nbw2 += _bitextDocument.document2().subAnnotationSet(seg, "token").size();
		}

		FeatureSet features = new FeatureSet();
		features.put("score", String.valueOf(score * _scoringMethod.score(nbw1, nbw2)));
		_alignments.add(0, new Alignment(list1, list2, features));
	}

	/**
	 * Gets list of annotations for specified segment span
	 * @param segmentList segment list
	 * @param startSegment start of the segment span
	 * @param endSegment end of the segment span
	 * @return
	 */
	private List<Annotation> getAnnotationList(AnnotationSet segmentList, int startSegment, int endSegment) {
		if (startSegment != -1 && endSegment != -1 && endSegment >= startSegment)
			return segmentList.subList(startSegment, endSegment + 1);
		else
			return EMPTY_ALIGNMENT;
	}

	/**
	 * Gets the alignment score between 2 segments
	 * @param x segment index in document1
	 * @param y segment index in document2
	 * @return alignment score
	 */
	private double getScore(int x, int y) {
		if (x < 0 || y < 0)
			return 0;
		else
			return _score[x][y];
	}

	/**
	 * Sets the alignment score between 2 segments
	 * @param x segment index in document1
	 * @param y segment index in document2
	 * @param d alignment score
	 */
	private void setScore(int x, int y, double d) {
		_score[x][y] = d;
	}

	/**
	 * Calculates alignment score between 2 segment spans  
	 * @param bitextDocument bitext document to align
	 * @param xStartSegment start of the segment span in document1
	 * @param xEndSegment end of the segment span in document1
	 * @param yStartSegment start of the segment span in document2
	 * @param yEndSegment end of the segment span in document2
	 * @return alignment score
	 */
	private double calculateSpanAlignmentScore(BitextDocument bitextDocument, int xStartSegment, int xEndSegment, int yStartSegment, int yEndSegment) {
		double length_penalty = 1;
		int nx = (xEndSegment != -1 && xStartSegment != -1) ? xEndSegment - xStartSegment + 1 : 0;
		int ny = (yEndSegment != -1 && yStartSegment != -1) ? yEndSegment - yStartSegment + 1 : 0;

		if (nx == 0 || ny == 0)
			return -0.1;

		double score = matchSegmentsLex(bitextDocument, xStartSegment, xEndSegment, yStartSegment, yEndSegment);
		// TODO: easier way to count tokens???
		int xlen = 0;
		for (int i = xStartSegment; i <= xEndSegment; i++)
			xlen += _documentTokenStat1.getSegmentLengths().get(i);
		int ylen = 0;
		for (int i = yStartSegment; i <= yEndSegment; i++)
			ylen += _documentTokenStat2.getSegmentLengths().get(i);

		// TODO: extract to weighting function, maybe propose others?
		if (Math.max(xlen, ylen / _xtoyc) > 60)
			length_penalty = Math.log(6 + 4 * Math.min(xlen * _xtoyc, ylen) / Math.max(xlen * _xtoyc, ylen)) / Math.log(10);

		return score * length_penalty * _penalty[nx][ny];
	}

	/**
	 * Calculates alignment score between 2 segment spans based on lexical information
	 * (rough dictionary-based translation)
	 * @param bitextDocument bitext document to align
	 * @param xStartSegment start of the segment span in document1
	 * @param xEndSegment end of the segment span in document1
	 * @param yStartSegment start of the segment span in document2
	 * @param yEndSegment end of the segment span in document2
	 * @return alignment score
	 */
	private double matchSegmentsLex(BitextDocument bitextDocument, int xStartSegment, int xEndSegment, int yStartSegment, int yEndSegment) {
		double score = 0;

		HashMap<String, Integer> tokenStat1 = getTokenStat(_tokenSegmentStat1, xStartSegment, xEndSegment);
		HashMap<String, Integer> tokenStat2 = getTokenStat(_tokenSegmentStat2, yStartSegment, yEndSegment);

		for (String xToken : tokenStat1.keySet()) {
			if (tokenStat2.containsKey(xToken) && !_xStopWords.contains(xToken)) // token
			{
				score += Math.log((_documentTokenStat1.getTotalTokens() / _documentTokenStat1.get(xToken))
						* Math.min(tokenStat1.get(xToken), tokenStat2.get(xToken)) + 1);
			} else {
				if (_dictionary.get(xToken) != null) {
					for (String translation : _dictionary.get(xToken)) {
						if (tokenStat2.containsKey(translation)) {
							int minPairs = Math.min(tokenStat1.get(xToken), tokenStat2.get(translation));
							if (minPairs != 0) {
								score += Math.log(_documentTokenStat1.getTotalTokens() / _documentTokenStat1.get(xToken) * minPairs + 1);
								tokenStat1.put(xToken, tokenStat1.get(xToken) - minPairs);
								tokenStat2.put(translation, tokenStat2.get(translation) - minPairs);
								break;
							}
						}
					}
				}
			}
		}
		return score;
	}
	
	/**
	 * Gets token statistics 
	 * @param tokenSegmentStat
	 * @param startSegment start segment index
	 * @param endSegment end segment index
	 * @return
	 */
	private HashMap<String, Integer> getTokenStat(ArrayList<HashMap<String, Integer>> tokenSegmentStat, int startSegment, int endSegment) {
		HashMap<String, Integer> tokenStat = new HashMap<String, Integer>();
		for (int i = startSegment; i <= endSegment; i++) {
			for (Entry<String, Integer> stat : tokenSegmentStat.get(i).entrySet()) {
				int cnt = tokenStat.get(stat.getKey()) != null ? stat.getValue() + 1 : 1;
				tokenStat.put((String) stat.getKey(), cnt);
			}
		}
		return tokenStat;
	}

	/**
	 * Parses bitext document
	 */
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

		align(bitextDocument); // TODO: !!!! there is an order here, to match with the dictionary
	}

	/**
	 * Initializes the champollion aligner
	 */
	@Override
	protected void init() {
		_penalty[1][1] = 1; // keep this one
		try {
			_xStopWords = new StopWords(new URL("file:" + _stoplistpath));
			_yStopWords = null; // TODO: implement
			_dictionary = new Dictionary(_xStopWords, new URL("file:" + _dictpath));
		} catch (MalformedURLException e) {
			e.printStackTrace();
		}

		_lemmaFeature1 = "string";
		_lemmaFeature2 = "string";

		System.out.println("New champollion aligner created");
	}
}
