package de.upb.reconos.grasp.gui;

import java.io.Serializable;

public class SimpleTimer extends Thread implements Serializable {

	private static final long serialVersionUID = 1L;
	private long periodMsec;
	private Task task;
	
	SimpleTimer(Task t, long msec){
		task = t;
		periodMsec = msec;
		//this.setPriority(Thread.MIN_PRIORITY);
	}
	
	public void run() {
		while(true){
			try {
				Thread.sleep(periodMsec);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			task.run();
		}
	}
}
