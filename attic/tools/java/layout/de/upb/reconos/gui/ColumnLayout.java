package de.upb.reconos.gui;

import java.awt.Component;
import java.awt.Container;
import java.awt.Dimension;

public class ColumnLayout extends SimpleLayout {

	private int horizontalSpacing;
	
	public ColumnLayout(){
		horizontalSpacing = 0;
	}
	
	public ColumnLayout(int horizontalSpacing){
		this.horizontalSpacing = horizontalSpacing;
	}
	
	public void layoutContainer(Container parent) {
		int height = parent.getHeight() - parent.getInsets().top - parent.getInsets().bottom;
		int w = parent.getInsets().left;
		
		Component[] comps = parent.getComponents();
		for(Component c : comps){
			int cw = c.getPreferredSize().width;
			
			c.setLocation(w, parent.getInsets().top);
			c.setSize(cw, height);
			
			w += cw + horizontalSpacing;
		}
	}

	public Dimension preferredLayoutSize(Container parent) {
		int w = 0;
		int h = 0;
		
		Component[] comps = parent.getComponents();
		for(Component c : comps){
			int cw = c.getPreferredSize().width;
			int ch = c.getPreferredSize().height;
			if(ch > h) h = ch;
			w += cw;
		}
		
		if(comps.length > 1){
			w += (comps.length - 1)*horizontalSpacing;
		}
		
		return new Dimension(w + parent.getInsets().left + parent.getInsets().right,
				h + parent.getInsets().top + parent.getInsets().bottom);
	}

}
