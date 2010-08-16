package de.upb.reconos.gui;

import java.awt.Component;
import java.awt.Container;
import java.awt.Dimension;

public class RowLayout extends SimpleLayout {

	private int verticalSpacing;
	
	public RowLayout(){
		verticalSpacing = 0;
	}
	
	public RowLayout(int verticalSpacing){
		this.verticalSpacing = verticalSpacing;
	}
	
	
	public void layoutContainer(Container parent) {
		int width = parent.getWidth() - parent.getInsets().left - parent.getInsets().right;
		int h = parent.getInsets().top;
		
		Component[] comps = parent.getComponents();
		for(Component c : comps){
			int ch = c.getPreferredSize().height;
			
			c.setLocation(parent.getInsets().left, h);
			c.setSize(width, ch);
			
			h += ch + verticalSpacing;
		}		
	}

	public Dimension preferredLayoutSize(Container parent) {
		int w = 32;
		int h = 0;
		
		Component[] comps = parent.getComponents();
		for(Component c : comps){
			int cw = c.getPreferredSize().width;
			int ch = c.getPreferredSize().height;
			if(cw > w) w = cw;
			h += ch;
		}
		
		if(comps.length > 1){
			h += (comps.length - 1)*verticalSpacing;
		}
		
		return new Dimension(w + parent.getInsets().left + parent.getInsets().right,
				h + parent.getInsets().top + parent.getInsets().bottom);
	}

	public int getVerticalSpacing() {
		return verticalSpacing;
	}

	public void setVerticalSpacing(int verticalSpacing) {
		this.verticalSpacing = verticalSpacing;
	}

}
