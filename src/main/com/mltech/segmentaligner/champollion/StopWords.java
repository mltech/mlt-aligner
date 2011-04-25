package com.mltech.segmentaligner.champollion;

import java.net.URL;
import java.util.ArrayList;

public class StopWords extends ArrayList<String>
{
	private static final long serialVersionUID = -4658296931794752720L;

	// TODO: re-implement
	public StopWords(URL path)
	{
	    System.out.println("Reading X stop list...");
	    
//	    BufferedReader br;
//		try
//		{
//			br = new BufferedReader(new FileReader(path.getPath()));
//			String line;
//		    while ((line = br.readLine()) != null) if (!this.contains(line)) this.add(line);
//		    br.close();
//		} catch (IOException e) {
//			// TODO Auto-generated catch block
//			e.printStackTrace();
//		}
	    System.out.println("done.");
	}
}
