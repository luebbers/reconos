package de.upb.reconos.grasp.objects;


import java.awt.Color;
import java.awt.Graphics2D;

import de.upb.reconos.grasp.gui.TextBlock;
import de.upb.reconos.grasp.math.Vector2d;
import de.upb.reconos.grasp.physics.ChargeDomain;
import de.upb.reconos.grasp.physics.ChargedPoint;
import de.upb.reconos.grasp.physics.FixedPointSet;
import de.upb.reconos.grasp.physics.Spring;



public class AnnotationNode extends Node {

	private static final long serialVersionUID = 1L;
	public ChargedPoint attachedPoint;
	public Spring spring;
	TextBlock textBlock;
	private FixedPointSet fixedPoints;
	
	public AnnotationNode(Node n, double x, double y) {
		super(n.world, n.getToplevelChargeDomain(), x, y);
		requires(n);
		
		attachedPoint = n.getCenterPoint();
		
		spring = new Spring(getCenterPoint(), attachedPoint);
		spring.springConstant = 2.0;
		spring.relaxedLength = 0;
		textBlock = new TextBlock(getCenterPoint().position);
		
		getCenterPoint().mass = 1.0;
		getCenterPoint().charge = 0.1;
		
		fixedPoints = new FixedPointSet();
		fixedPoints.points.add(getCenterPoint());
		fixedPoints.points.add(new ChargedPoint(1,0));
		fixedPoints.points.add(new ChargedPoint(-1,0));
		fixedPoints.points.get(1).position.add(getCenterPoint().position);
		fixedPoints.points.get(2).position.add(getCenterPoint().position);
		fixedPoints.points.get(1).charge = 0.07;
		fixedPoints.points.get(2).charge = 0.07;
		
		style.setFgColor(new Color(0.0f,0.0f,0.0f,1.0f));
		style.setBgColor(new Color(0.0f,0.0f,0.0f,0.05f));
		style.setLineWidth(2.0);
		style.setFontSize(15);
	}

	public void applyForce(){
		super.applyForce();
		spring.applyForce();
	}
	
	public void update(double dt){
		fixedPoints.update(dt);
	}
	
	public void addToChargeDomain(ChargeDomain cd){
		for(ChargedPoint p : fixedPoints.points){
			System.err.println("adding " + p);
			cd.add(p);
		}
	}
	
	public void removeFromChargeDomain(ChargeDomain cd){
		for(ChargedPoint p : fixedPoints.points){
			cd.add(p);
		}
	}
	
	public void draw(Graphics2D g2d) {
		style.apply(g2d);
		//style.drawRoundedRect(g2d, centerPoint.position, textBlock.width*1.2, textBlock.height*1.2);
		Vector2d a = Vector2d.add(getCenterPoint().position, new Vector2d(textBlock.width*0.6,textBlock.height*0.6));
		Vector2d b = Vector2d.add(getCenterPoint().position, new Vector2d(-textBlock.width*0.6,textBlock.height*0.6));
		style.drawLine(g2d, a, b, false, false);
		style.drawLine(g2d, a, attachedPoint.position, false, false);
		textBlock.draw(g2d);
		
		double x0 = getCenterPoint().position.getX();
		double y0 = getCenterPoint().position.getY();
		fixedPoints.points.get(1).position.setY(y0);
		fixedPoints.points.get(1).position.setX(x0 - textBlock.width/2);
		fixedPoints.points.get(2).position.setY(y0);
		fixedPoints.points.get(2).position.setX(x0 + textBlock.width/2);
	}
	
	public boolean contains(double x, double y) {
		return textBlock.contains(x, y);
	}

	public boolean isDraggable() {
		return true;
	}
	
	public void dragTo(double x, double y){
		getCenterPoint().position.add(x,y);
	}	
}
