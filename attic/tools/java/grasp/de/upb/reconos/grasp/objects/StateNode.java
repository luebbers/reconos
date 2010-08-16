package de.upb.reconos.grasp.objects;


import java.awt.Graphics2D;
import java.util.HashMap;
import java.util.Map;

import de.upb.reconos.grasp.gui.TextBlock;
import de.upb.reconos.grasp.math.Circle;
import de.upb.reconos.grasp.math.Vector2d;
import de.upb.reconos.grasp.physics.Spring;


public class StateNode extends MasterNode {

	private static final long serialVersionUID = 1L;

	public static int nextID(){ return counter++; }
	private static int counter = 0;
	
	private Circle circle;
	private TextBlock textBlock;
	private Map<ConnectionNode, Spring> springs;
	
	public StateNode(StateMachineNode parent,
			double x, double y, double radius)
	{
		super(parent.world, parent.getLocalChargeDomain(), x, y);
		requires(parent);
		
		parent.addStateNode(this);
		
		circle = new Circle(x, y, radius);
		getCenterPoint().position = circle.center;
		getCenterPoint().mass = 100;
		getCenterPoint().charge = 25;
		
		springs = new HashMap<ConnectionNode, Spring>();
		
		textBlock = new TextBlock(circle.center);
		style.setFontSize(30);
	}

	public void setName(String s){
		textBlock.setText(s);
	}
	
	public void draw(Graphics2D g2d) {
		style.drawCircle(g2d, circle);
		textBlock.draw(g2d);
	}
	
	public boolean contains(double x, double y) {
		return circle.contains(x,y);
	}

	public void onClick(int button, double x, double y) {
		if(button == 1){
			Vector2d p = circle.closestPoint(new Vector2d(x,y));
			Vector2d q = circle.closestPoint(new Vector2d(x,y),100);
			world.createStateConnection(this,p.getX(), p.getY(), q.getX(), q.getY());
		}
		else if(button == 2){
			Vector2d p = circle.closestPoint(new Vector2d(x,y));
			Vector2d q = circle.closestPoint(new Vector2d(x,y),100);
			world.createSignalConnection(this,p.getX(), p.getY(), q.getX(), q.getY());
		}
	}
	
	public void attach(ConnectionNode n){
		super.attach(n);
		double x = n.getCenterPoint().position.getX();
		double y = n.getCenterPoint().position.getY();
		Vector2d p = circle.closestPoint(new Vector2d(x,y));
		n.getCenterPoint().position.set(p.getX(), p.getY());
		
		Spring s = new Spring(getCenterPoint(), n.getCenterPoint(), 50);
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
	
