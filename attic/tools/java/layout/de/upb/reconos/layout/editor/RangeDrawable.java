package de.upb.reconos.layout.editor;

import java.awt.Color;
import java.awt.Graphics2D;

import de.upb.reconos.gui.Drawable;

public class RangeDrawable implements Drawable {

	private Color color;
	private Range range;
	
	public RangeDrawable(Range r, Color c){
		color = c;
		range = r;
	}
	
	public void draw(Graphics2D g2d) {
		double w = range.getXMax() + 1 - range.getXMin();
		double h = range.getYMax() + 1 - range.getYMin();
		g2d.setColor(color);
		g2d.fillRect((int)range.getXMin(), (int)range.getYMin(), (int)w, (int)h);	
	}
}
