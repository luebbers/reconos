package de.upb.reconos.grasp.objects;


import java.awt.Graphics2D;

import de.upb.reconos.grasp.gui.RenderStyle;
import de.upb.reconos.grasp.math.Vector2d;
import de.upb.reconos.grasp.physics.Spring;


public class Edge extends Element {

	private static final long serialVersionUID = 1L;
	public Node nodeA, nodeB;
	public Spring spring;
	public boolean arrowA;
	public boolean arrowB;
	public RenderStyle style;
	
	public Edge(World w, Node a, Node b){
		super(w);
		requires(a);
		requires(b);
		nodeA = a;
		nodeB = b;
		spring = new Spring(a.getCenterPoint(),b.getCenterPoint());
		spring.springConstant = 2;
		arrowA = false;
		arrowB = true;
		style = new RenderStyle();
		style.setLineWidth(6.0);
		style.setArrowSize(40);
	}
	
	public void draw(Graphics2D g2d) {
		Vector2d a = nodeA.getPosition();
		Vector2d b = nodeB.getPosition();
		style.drawLine(g2d, a, b, arrowA, arrowB);
	}
	
	public void update(double dt) {}
	
	public void applyForce(){
		spring.applyForce();
	}
	
	public Vector2d getPosition(){
		Vector2d a = new Vector2d(0,0);
		a.add(nodeA.getPosition());
		a.add(nodeB.getPosition());
		a.mul(0.5);
		return a;
	}
}
