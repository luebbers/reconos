package de.upb.reconos.grasp.objects;

import java.awt.Color;



public class PortNode extends SignalNode {

	private static final long serialVersionUID = 1L;

	public static int nextID(){ return counter++; }
	private static int counter = 0;
	
	public PortNode(StateMachineNode parent, double x, double y,
			double width, double height){
		super(parent,x,y, width, height);
		
		parent.removeSignalNode(this);
		
		//getToplevelChargeDomain().remove(getCenterPoint());
		parent.getPortChargeDomain().add(getCenterPoint());
		
		getCenterPoint().charge = 5;
		style.setBgColor(Color.RED);
	}
}
