package de.upb.reconos.grasp.tests;


import javax.swing.JFrame;

import de.upb.reconos.grasp.gui.MainFrame;


public class Test {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		MainFrame t = new MainFrame("Foo");
		t.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		t.setVisible(true);
	}

}
