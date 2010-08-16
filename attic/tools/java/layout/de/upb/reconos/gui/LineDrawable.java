package de.upb.reconos.gui;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.geom.Line2D;

public class LineDrawable implements Drawable {
	private Vector2d a;
	private Vector2d b;
	private Color color;
	private float lineWidth;
	
	public LineDrawable(Vector2d va, Vector2d vb, Color c, float lineWidth){
		a = va;
		b = vb;
		color = c;
		this.lineWidth = lineWidth;
	}

	public void draw(Graphics2D g2d) {
		g2d.setColor(color);
		g2d.setStroke(new BasicStroke(lineWidth));
		g2d.draw(new Line2D.Double(a.getX(), a.getY(), b.getX(), b.getY()));
	}
}
