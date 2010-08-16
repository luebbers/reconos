package de.upb.reconos.layout.editor;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics2D;

import de.upb.reconos.gui.Drawable;

public class RangeBorderDrawable implements Drawable {
	private Color color;
	private Range range;
	private float lineWidth;
	
	public RangeBorderDrawable(Range r, Color c, float lineWidth){
		color = c;
		range = r;
		this.lineWidth = lineWidth;
	}
	
	public void draw(Graphics2D g2d) {
		double w = range.getXMax() + 1 - range.getXMin();
		double h = range.getYMax() + 1 - range.getYMin();
		g2d.setColor(color);
		g2d.setStroke(new BasicStroke(lineWidth));
		g2d.drawRect((int)range.getXMin(), (int)range.getYMin(), (int)w, (int)h);	
	}
}
