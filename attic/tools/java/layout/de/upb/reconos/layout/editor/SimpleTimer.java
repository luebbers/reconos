package de.upb.reconos.layout.editor;
import java.io.Serializable;




public class SimpleTimer extends Thread implements Serializable {

	private static final long serialVersionUID = 1L;
	private long periodMsec;
	private Editor mainFrame;
	
	SimpleTimer(Editor mf, long msec){
		mainFrame = mf;
		periodMsec = msec;
	}
	
	public void run() {
		while(true){
			try {
				Thread.sleep(periodMsec);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			mainFrame.invalidate();
			mainFrame.repaint();
			mainFrame.renderPanel.invalidate();
			mainFrame.renderPanel.repaint();
		}
	}
}