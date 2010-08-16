package de.upb.reconos.layout.editor;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics2D;

import de.upb.reconos.gui.Drawable;

public class GridDrawable implements Drawable {

	private Color color;
	private Range range;
	private float lineWidth;
	
	public GridDrawable(Range r, Color c, float lineWidth){
		color = c;
		range = r;
		this.lineWidth = lineWidth;
	}
	
	public void draw(Graphics2D g2d) {
		g2d.setColor(color);
		g2d.setStroke(new BasicStroke(lineWidth));
		for(int i = range.getXMin(); i < range.getXMax() + 1; i++){
			if(i % 2 == 0){
				g2d.drawLine(i,range.getYMin(),i,range.getYMax());
			}
		}
		for(int i = range.getYMin(); i < range.getYMax() + 1; i++){
			if(i % 2 == 0){
				g2d.drawLine(range.getXMin(),i,range.getXMax(),i);
			}
		}
	}
}
