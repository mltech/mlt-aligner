package com.mltech.segmentaligner.champollion.scoring;

public enum ScoringMethod {
	WATGT(new WordAvgTgt()),
	WASRC(new WordAvgSrc()),
	WAMIN(new WordAvgMinSrcTgt()),
	WAMAX(new WordAvgMaxSrcTgt()),
	WAMEAN(new WordAvgMeanSrcTgt());

	private final IAlignmentScoreNormalizingMethod method;

	public IAlignmentScoreNormalizingMethod method() {
		return method;
	}

	private ScoringMethod(IAlignmentScoreNormalizingMethod method) {
		this.method = method;
	}
}

class WordAvgTgt implements IAlignmentScoreNormalizingMethod {
	public double score(double nbw1, double nbw2) {
		return 1 / (nbw2 + 1);
	}
}

class WordAvgSrc implements IAlignmentScoreNormalizingMethod {
	public double score(double nbw1, double nbw2) {
		return 1 / (nbw1 + 1);
	}
}

class WordAvgMinSrcTgt implements IAlignmentScoreNormalizingMethod {
	public double score(double nbw1, double nbw2) {
		return 1 / (Math.min(nbw1, nbw2) + 1);
	}
}

class WordAvgMaxSrcTgt implements IAlignmentScoreNormalizingMethod {
	public double score(double nbw1, double nbw2) {
		return 1 / (Math.max(nbw1, nbw2) + 1);
	}
}

class WordAvgMeanSrcTgt implements IAlignmentScoreNormalizingMethod {
	public double score(double nbw1, double nbw2) {
		return 1 / ((nbw1 + nbw2) / 2 + 1);
	}
}