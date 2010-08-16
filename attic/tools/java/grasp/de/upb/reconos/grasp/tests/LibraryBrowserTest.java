package de.upb.reconos.grasp.tests;


import javax.swing.JFrame;

import de.upb.reconos.grasp.gui.LibraryBrowser;


public class LibraryBrowserTest extends JFrame {

	private static final long serialVersionUID = 1L;
	LibraryBrowser fb;
	
	public LibraryBrowserTest(){
		fb = new LibraryBrowser();
		getContentPane().add(fb);
	}
	
	public static void main(String[] args) {
		LibraryBrowserTest e = new LibraryBrowserTest();
		e.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		e.setSize(640,480);
		e.setVisible(true);
	}

}
