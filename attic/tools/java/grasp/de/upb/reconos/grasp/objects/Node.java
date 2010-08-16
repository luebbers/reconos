package de.upb.reconos.grasp.objects;


import java.awt.Color;

import de.upb.reconos.grasp.gui.RenderStyle;
import de.upb.reconos.grasp.interfaces.Interactable;
import de.upb.reconos.grasp.math.Vector2d;
import de.upb.reconos.grasp.physics.ChargeDomain;
import de.upb.reconos.grasp.physics.ChargedPoint;


public abstract class Node extends Element implements Interactable {
	private ChargedPoint centerPoint;
	protected RenderStyle style;
	protected ChargeDomain toplevelChargeDomain;
	
	public Node(World w, ChargeDomain toplevel, double x, double y){
		super(w);
		centerPoint = new ChargedPoint(x,y);
		toplevelChargeDomain = toplevel;
		toplevel.add(centerPoint);
		style = new RenderStyle();
		style.setLineWidth(4.0);
		style.setBgColor(new Color(0.9f,0.9f,1.0f));
	}
	
	public void dissolve(){
		toplevelChargeDomain.remove(centerPoint);
		super.dissolve();
	}
	
	public void update(double dt) {
		centerPoint.update(dt);
	}
	
	public void dragReleased(double x, double y){}
	
	public boolean contains(double x, double y) {
		return false;
	}

	public void onClick(int button, double x, double y) {	
	}
	
	public Vector2d getPosition(){
		return centerPoint.position;
	}

	public ChargeDomain getToplevelChargeDomain(){
		return toplevelChargeDomain;
	}

	public ChargedPoint getCenterPoint() {
		return centerPoint;
	}

	public boolean isDraggable() {
		return true;
	}
	
	public void dragTo(double x, double y){
		getCenterPoint().position.add(x,y);
	}

	public void applyForce() {
	}
	
}
