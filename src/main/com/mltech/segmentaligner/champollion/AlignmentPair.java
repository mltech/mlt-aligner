package com.mltech.segmentaligner.champollion;

public enum AlignmentPair {
	PAIR11(1, 1),
	PAIR10(1, 0),
	PAIR01(0, 1),
	PAIR21(2, 1),
	PAIR12(1, 2),
	PAIR22(2, 2),
	PAIR13(1, 3),
	PAIR31(3, 1),
	PAIR23(2, 3),
	PAIR32(3, 2),
	//	PAIR33(3, 3), TODO: not used ??
	PAIR14(1, 4),
	PAIR41(4, 1);

	private final int segment1;
	private final int segment2;

	private AlignmentPair(int segment1, int segment2) {
		this.segment1 = segment1;
		this.segment2 = segment2;
	}

	public int segment1() {
		return segment1;
	}

	public int segment2() {
		return segment2;
	}
}
