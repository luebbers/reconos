package de.upb.reconos.grasp.objects;


import java.awt.Color;
import java.awt.Graphics2D;
import java.util.HashMap;
import java.util.Map;

import de.upb.reconos.grasp.gui.TextBlock;
import de.upb.reconos.grasp.math.CenterPointRectangle;
import de.upb.reconos.grasp.math.Circle;
import de.upb.reconos.grasp.math.Vector2d;
import de.upb.reconos.grasp.physics.RectangleSpring;
import de.upb.reconos.grasp.physics.Spring;


public class SignalNode extends MasterNode {

	private static final long serialVersionUID = 1L;

	public static int nextID(){ return counter++; }
	private static int counter = 0;
	
	private CenterPointRectangle rectangle;
	private TextBlock textBlock;
	private Map<ConnectionNode, Spring> springs;
	
	public SignalNode(StateMachineNode parent, double x,
			double y, double width, double height)
	{
		super(parent.world, parent.getLocalChargeDomain(), x, y);
		requires(parent);

		parent.addSignalNode(this);
		
		rectangle = new CenterPointRectangle(x, y, width, height);
		getCenterPoint().position = rectangle.getCenter();
		getCenterPoint().mass = 200;
		getCenterPoint().charge = 32;
		
		springs = new HashMap<ConnectionNode, Spring>();
		
		textBlock = new TextBlock(new Vector2d());
		textBlock.center = getCenterPoint().position;
		
		style.setBgColor(new Color(0.9f,1.0f,0.9f));
		style.setFontSize(30);
	}
	
	public CenterPointRectangle getRectangle(){
		return rectangle;
	}
	
	public void setName(String s){
		textBlock.setText(s);
	}
	
	public void draw(Graphics2D g2d) {
		style.drawRoundedRect(g2d,
				getCenterPoint().position.getX(),
				getCenterPoint().position.getY(),
				rectangle.getWidth(), rectangle.getHeight());
		textBlock.draw(g2d);
	}
	
	public boolean contains(double x, double y) {
		return rectangle.contains(x,y);
	}
	
	public void attach(ConnectionNode n){
		super.attach(n);
		
		double x = n.getCenterPoint().position.getX();
		double y = n.getCenterPoint().position.getY();
		
		double r = Math.max(rectangle.getHeight(), rectangle.getWidth());
		Circle tmp = new Circle(getCenterPoint().position.getX(),
				getCenterPoint().position.getX(), r);
		Vector2d p = tmp.closestPoint(new Vector2d(x,y));
		n.getCenterPoint().position.set(p.getX(), p.getY());
		
		Spring s = new RectangleSpring(rectangle,
				getCenterPoint(), n.getCenterPoint(), 10000);
		springs.put(n, s);
	}
	
	public void detach(ConnectionNode n){
		springs.remove(n);
		super.detach(n);
	}
	
	public void applyForce(){
		super.applyForce();
		for(Spring s : springs.values()){
			s.applyForce();
		}
	}
}
