package de.upb.reconos.grasp.objects;


import java.awt.Color;
import java.awt.Graphics2D;

import de.upb.reconos.grasp.math.Circle;
import de.upb.reconos.grasp.physics.ChargeDomain;


public class StateConnectionNode extends ConnectionNode {

	private static final long serialVersionUID = 1L;
	private Circle circle;
	
	public StateConnectionNode(World w, ChargeDomain toplevel,
			double x, double y, double radius)
	{
		super(w, toplevel, x, y);
		
		circle = new Circle(x, y, radius);
		
		getCenterPoint().position = circle.center;
		getCenterPoint().mass = 1.0;
		getCenterPoint().charge = 0.5;
		
		style.setBgColor(Color.BLUE);
	}
	
	public void draw(Graphics2D g2d) {
		style.drawCircle(g2d, circle);
	}
	
	public boolean contains(double x, double y) {
		return circle.contains(x,y);
	}
	
	public void dragReleased(double x, double y){
		StateNode n = world.getStateNode(x,y);
		if(n == null){
			System.out.println("State: connect failed, no State node");
		}
		else{
			World.connect(n, this, false);
		}
	}
}
