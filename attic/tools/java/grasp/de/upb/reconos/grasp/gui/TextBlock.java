package de.upb.reconos.grasp.gui;


import java.awt.Graphics2D;
import java.awt.geom.Rectangle2D;
import java.io.Serializable;
import java.util.Vector;

import de.upb.reconos.grasp.math.Vector2d;


public class TextBlock implements Serializable {

	private static final long serialVersionUID = 1L;
	public Vector2d center;
	private Vector<String> lines;
	public double width;
	public double height;
	public double offset;
	public int alignment;
	public static int ALIGN_LEFT = 0;
	public static int ALIGN_CENTER = 1;
	
	public TextBlock(Vector2d center){
		lines = new Vector<String>();
		this.center = center;
		alignment = ALIGN_CENTER;
	}
	
	public void addText(String s){
		String[] res = s.split("\n");
		for(int i = 0; i < res.length; i++){
			lines.add(res[i]);
		}
	}
	
	public void setText(String s){
		clear();
		addText(s);
	}
	
	public void clear(){
		lines.removeAllElements();
	}
	
	public String getText(){
		String res = "";
		for(String l : lines){
			res += l + "\n";
		}
		return res;
	}
	
	public void computeBounds(Graphics2D g2d){
		width = height = offset = 0;
		for(int i = 0; i < lines.size(); i++){ 
			Rectangle2D r = g2d.getFont().getStringBounds(
					lines.get(i), g2d.getFontRenderContext());
			if(i == 0) offset = r.getY();
			if(r.getWidth() > width) width = r.getWidth();
			height += r.getHeight();
		}
		
	}
	
	public void draw(Graphics2D g2d){
		computeBounds(g2d);
		for(int i = 0; i < lines.size(); i++){
			Rectangle2D r = g2d.getFont().getStringBounds(
					lines.get(i), g2d.getFontRenderContext());
			double x;
			if(alignment == ALIGN_CENTER){
				x = center.getX() - r.getWidth()/2;
			}
			else{
				x = center.getX() - width/2;
			}
			double y = center.getY() - offset + i*height/lines.size() - height/2;
			g2d.drawString(lines.get(i), (float)x, (float)y);
		}
	}
	
	public boolean contains(double x, double y){
		if(x < center.getX() - width/2) return false;
		if(x > center.getX() + width/2) return false;
		if(y < center.getY() - height/2) return false;
		if(y > center.getY() + height/2) return false;
		return true;
	}
}
