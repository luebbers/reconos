package de.upb.reconos.gui;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.geom.AffineTransform;
import java.awt.geom.Rectangle2D;
import java.util.Vector;



public class TextBlock implements Drawable {
	public Vector2d center;
	private Vector<String> lines;
	public double width;
	public double height;
	public double offset;
	public int alignment;
	public static int ALIGN_LEFT = 0;
	public static int ALIGN_CENTER = 1;
	public Font font;
	public double scale;
	public double rotation;
	private Color color;
	
	public TextBlock(Vector2d center){
		lines = new Vector<String>();
		this.center = center;
		alignment = ALIGN_CENTER;
		font = new Font("monospaced",Font.BOLD,1);
		color = Color.BLACK;
		scale = 1;
		rotation = 0;
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
	
	public double old_x;
	public double old_y;
	
	public void draw(Graphics2D g2d_){
		Graphics2D g2d = (Graphics2D)g2d_.create();
		g2d.setFont(font);
		
		AffineTransform af = g2d.getTransform(); 
		g2d.setTransform(new AffineTransform());
		
		computeBounds(g2d);
		for(int i = 0; i < lines.size(); i++){
			g2d.setTransform(new AffineTransform());
			Rectangle2D r = g2d.getFont().getStringBounds(
					lines.get(i), g2d.getFontRenderContext());
			
			g2d.setTransform(af);
			
			double x;
			if(alignment == ALIGN_CENTER){
				x = center.getX() - 0.5*r.getWidth();
			}
			else{
				x = center.getX();// - 0.5*width;
			}
			double y = center.getY() - offset + 1.0*i*height/lines.size() - 0.5*height;
			g2d.setColor(color);
			
			//System.out.println("x = " + x + "  rect = " + r);
			
			// mirror text because we work in inverse y-coordinates
			g2d.translate(x, y);
			g2d.scale(scale, -scale);
			g2d.rotate(rotation);
			g2d.drawString(lines.get(i), 0f,0f);
			g2d.rotate(-rotation);
			g2d.scale(1/scale, -1/scale);
			g2d.translate(-x, -y);
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
