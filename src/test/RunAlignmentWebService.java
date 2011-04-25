import java.net.MalformedURLException;
import java.net.URL;

import com.mltech.laf.restws.BitextDocumentPipelineApplication;
import com.mltech.laf.restws.PipelineServer;


public class RunAlignmentWebService {
	public static void main(String[] args) throws MalformedURLException {
		PipelineServer ps = new PipelineServer(8181);
		ps.addApplication(new BitextDocumentPipelineApplication(new URL("file:../settings/conf-test/alignment-test.pipeline"), "/align"));
		ps.start();
	}
}