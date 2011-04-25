package com.mltech.segmentaligner.champollion;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;

public class Dictionary extends HashMap<String, ArrayList<String>>
{
	private static final long serialVersionUID = -6042695957809492195L;

	public Dictionary(StopWords stopWords, URL path)
	{

		BufferedReader br;
		try
		{
			br = new BufferedReader(new FileReader(path.getPath()));
			String line;
			String tmp[];
			String source;
			String translation;
			while ((line = br.readLine()) != null)
			{

				tmp = line.split(" <> ");
				source = tmp[0].trim();
				source = source.toLowerCase();
				if (!stopWords.contains(source))
				{
					translation = tmp[1].trim();
					ArrayList<String> translations = this.get(source);
					if (translations == null)
					{
						translations = new ArrayList<String>();
						this.put(source, translations);
					}
					translations.add(translation);
				}
			}
			br.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		System.out.println("done.");
		System.out.println("Number of entries: " + this.size());
	}
}
