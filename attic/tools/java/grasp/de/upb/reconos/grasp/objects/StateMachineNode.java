package de.upb.reconos.grasp.objects;


import java.awt.Color;
import java.awt.Graphics2D;
import java.util.Vector;

import de.upb.reconos.grasp.gui.TextBlock;
import de.upb.reconos.grasp.interfaces.Rectangle;
import de.upb.reconos.grasp.math.CenterPointRectangle;
import de.upb.reconos.grasp.math.ScaledRectangle;
import de.upb.reconos.grasp.math.Vector2d;
import de.upb.reconos.grasp.physics.ChargeDomain;
import de.upb.reconos.grasp.physics.DualHorizontalForceField;
import de.upb.reconos.grasp.physics.InverseRectangularForceField;


public class StateMachineNode extends ChargeDomainNode {

	private static final long serialVersionUID = 1L;

	public static int nextID(){ return counter++; }
	private static int counter = 0;
	
	private CenterPointRectangle forceRectangle;
	private ScaledRectangle viewRectangle;
	private TextBlock textBlock;
	private Vector<StateNode> stateNodes;
	private Vector<SignalNode> signalNodes;
	private Vector<PortNode> portNodes;
	private InverseRectangularForceField forceField;
	private DualHorizontalForceField portForceField;
	private ChargeDomain portChargeDomain;
	
	public StateMachineNode(World w, ChargeDomain toplevel,
			double x, double y, double width, double height)
	{
		super(w, toplevel, x ,y);
		forceRectangle = new CenterPointRectangle(x,y, width, height);
		viewRectangle = new ScaledRectangle(forceRectangle,
				1.2, 1.2, 300, 300);
		getCenterPoint().position = forceRectangle.getCenter();
		getCenterPoint().mass = 1000;
		getCenterPoint().charge = 100;
		
		forceField = new InverseRectangularForceField(
				forceRectangle,getCenterPoint(),200);
		getLocalChargeDomain().add(forceField);
		
		textBlock = new TextBlock(new Vector2d());
		
		stateNodes = new Vector<StateNode>();
		signalNodes = new Vector<SignalNode>();
		portNodes = new Vector<PortNode>();
		
		portForceField = new DualHorizontalForceField(
				getCenterPoint(), 50, width, height);
		portChargeDomain = new ChargeDomain();
		portChargeDomain.add(portForceField);
		
		world.addChargeDomain(portChargeDomain);

		style.setBgColor(new Color(1.0f,1.0f,0.9f));
		style.setFontSize(60);
	}
	
	public void dragTo(double dx, double dy){
		getCenterPoint().position.add(dx,dy);
		forceField.setCenter(getCenterPoint().position.getX(),
				getCenterPoint().position.getY());
		for(StateNode n : stateNodes){
			n.dragTo(dx, dy);
		}
		for(SignalNode n : signalNodes){
			n.dragTo(dx,dy);
		}
		for(PortNode n : portNodes){
			n.dragTo(dx,dy);
		}
	}
	
	public void addStateNode(StateNode n){
		stateNodes.add(n);
	}
	
	public void removeStateNode(StateNode n){
		while(stateNodes.remove(n));
	}
	
	public void addSignalNode(SignalNode n){
		signalNodes.add(n);
	}
	
	public void removeSignalNode(SignalNode n){
		while(signalNodes.remove(n));
	}
	
	public void setName(String s){
		textBlock.setText(s);
	}
	
	public void draw(Graphics2D g2d) {
		style.drawRoundedRect(g2d, 
				getCenterPoint().position.getX(),
				getCenterPoint().position.getY(),
				viewRectangle.getWidth(), viewRectangle.getHeight());
		double x = getCenterPoint().position.getX();
		double y = getCenterPoint().position.getY() 
				- viewRectangle.getHeight()*0.5 - textBlock.height;
		textBlock.center.set(x, y);
		textBlock.draw(g2d);
		
		portForceField.width = viewRectangle.getWidth();
		portForceField.height = viewRectangle.getHeight()*0.6;
	}
	
	public boolean contains(double x, double y) {
		return viewRectangle.contains(x,y);
	}
	
	public void attach(PortNode n){
		portNodes.add(n);
		forceField.exclude.add(n.getCenterPoint());
	}
	
	public Rectangle getViewRectangle() {
		return viewRectangle;
	}

	public ChargeDomain getPortChargeDomain() {
		return portChargeDomain;
	}
}
