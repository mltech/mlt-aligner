package com.mltech.segmentaligner.champollion.scoring;

public interface IAlignmentScoreNormalizingMethod {
	double score(double nbw1, double nbw2);
}
