package de.upb.reconos.grasp.gui;


import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.io.Serializable;

import de.upb.reconos.grasp.interfaces.Rectangle;
import de.upb.reconos.grasp.math.Circle;
import de.upb.reconos.grasp.math.Vector2d;


public class RenderStyle implements Serializable {

	private static final long serialVersionUID = 1L;
	private double lineWidth;
	private double arrowSize;
	private Color fgColor;
	private Color bgColor;
	private Font font;
	
	public RenderStyle(){
		lineWidth = 1;
		fgColor = Color.BLACK;
		bgColor = Color.WHITE;
		font = new Font("monospaced",0,30);
		arrowSize = 40;
	}
	
	public void setFontSize(int s){
		font = new Font(font.getFontName(),font.getStyle(), s);
	}
	
	public void apply(Graphics2D g2d){
		g2d.setStroke(new BasicStroke((float)lineWidth));
		g2d.setColor(fgColor);
		g2d.setBackground(bgColor);
		g2d.setFont(font);
	}

	public void drawCircle(Graphics2D g2d, Circle c){
		int x = (int)(c.center.getX() - c.radius);
		int y = (int)(c.center.getY() - c.radius);
		int s = (int)(c.radius*2);
		apply(g2d);
		g2d.setColor(getBgColor());
		g2d.fillOval(x, y, s, s);
		g2d.setColor(getFgColor());
		g2d.drawOval(x, y, s, s);
	}
	
	public void drawLine(Graphics2D g2d, Vector2d a, Vector2d b,
			boolean arrowA, boolean arrowB)
	{
		apply(g2d);
		g2d.drawLine((int)a.getX(),(int)a.getY(),(int)b.getX(),(int)b.getY());
		if(arrowA || arrowB){
			Vector2d ab = Vector2d.sub(b,a);
			ab.setLength(arrowSize);
			Vector2d abT = new Vector2d(ab.getY(), -ab.getX());
			abT.mul(0.5);
			Vector2d ac = Vector2d.add(ab,abT);
			Vector2d ad = Vector2d.sub(ab,abT);
			if(arrowA){
				Vector2d c = Vector2d.add(a,ac);
				Vector2d d = Vector2d.add(a,ad);
				g2d.drawLine((int)a.getX(), (int)a.getY(),
						(int)c.getX(), (int)c.getY());
				g2d.drawLine((int)a.getX(), (int)a.getY(),
						(int)d.getX(), (int)d.getY());
			}
			if(arrowB){
				ac.mul(-1);
				ad.mul(-1);
				Vector2d c = Vector2d.add(b,ac);
				Vector2d d = Vector2d.add(b,ad);
				g2d.drawLine((int)b.getX(), (int)b.getY(),
						(int)c.getX(), (int)c.getY());
				g2d.drawLine((int)b.getX(), (int)b.getY(),
						(int)d.getX(), (int)d.getY());
			}
		}
	}
	
	public void drawRoundedRect(Graphics2D g2d, double x, double y,
			double width, double height)
	{
		int m = (int)Math.min(width/4,height/4);
		
		apply(g2d);
		g2d.setColor(getBgColor());
		g2d.fillRoundRect((int)(x - width/2), (int)(y - height/2),
				(int)width, (int)height, m, m);
		g2d.setColor(getFgColor());
		g2d.drawRoundRect((int)(x - width/2), (int)(y - height/2),
				(int)width, (int)height, m, m);
	}

	public void drawRoundedRect(Graphics2D g2d, Rectangle rect){
		drawRoundedRect(g2d,rect.getCenterX(), rect.getCenterY(),rect.getWidth(), rect.getHeight());
	}
	
	public Color getBgColor() {
		return bgColor;
	}

	public void setBgColor(Color bgColor) {
		this.bgColor = bgColor;
	}

	public Color getFgColor() {
		return fgColor;
	}

	public void setFgColor(Color fgColor) {
		this.fgColor = fgColor;
	}

	public Font getFont() {
		return font;
	}

	public void setFont(Font font) {
		this.font = font;
	}

	public double getLineWidth() {
		return lineWidth;
	}

	public void setLineWidth(double lineWidth) {
		this.lineWidth = lineWidth;
	}

	public double getArrowSize() {
		return arrowSize;
	}

	public void setArrowSize(double arrowSize) {
		this.arrowSize = arrowSize;
	}
}
