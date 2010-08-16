package de.upb.reconos.grasp.objects;


import java.io.Serializable;
import java.util.Vector;

import de.upb.reconos.grasp.interfaces.Animated;
import de.upb.reconos.grasp.interfaces.Drawable;
import de.upb.reconos.grasp.interfaces.Interactable;
import de.upb.reconos.grasp.math.Vector2d;
import de.upb.reconos.grasp.physics.ChargeDomain;


public class World implements Serializable {

	private static final long serialVersionUID = 1L;
	public static int LAYER_STATE_MACHINE_NODE = 0;
	public static int LAYER_STATE_NODE = 1;
	public static int LAYER_SIGNAL_NODE = 1;
	public static int LAYER_CONNECTION_NODE = 2;
	public static int LAYER_CONNECTION_EDGE = 3;
	public static int LAYER_ANNOTATION_NODE = 4;
	public static int LAYER_COUNT = 5;

	public static void connect(StateMachineNode sm, PortNode p)
	{
		sm.attach(p);
		p.requires(sm);
	}
	
	public static boolean connect(MasterNode master,
			ConnectionNode slave, boolean fixed)
	{
		if(master.accepts(slave) && slave.accepts(master)){
			master.attach(slave);
			slave.attach(master);
			if(fixed) slave.fix();
			return true;
		}
		System.err.println("World::connect failed: master.accepts = "
				+ master.accepts(slave) + " slave.accepts = "
				+ slave.accepts(master));
		return false;
	}
	
	public static void disconnect(MasterNode master, ConnectionNode slave){
		master.detach(slave);
		slave.detach();
	}
	
	private MultiLayer<Drawable> drawables;
	private MultiLayer<Interactable> interactables;
	private Vector<Animated> animated;
	
	private Vector<ChargeDomain> chargeDomains;
	
	private Vector<Element> elements;
	private Vector<StateNode> stateNodes;
	private Vector<SignalNode> signalNodes;
	private Vector<Edge> edges;
	private Vector<AnnotationNode> annotations;
	
	public World(){
		animated = new Vector<Animated>();
		drawables = new MultiLayer<Drawable>(LAYER_COUNT);
		interactables = new MultiLayer<Interactable>(LAYER_COUNT);
		
		chargeDomains = new Vector<ChargeDomain>();
		
		elements = new Vector<Element>();
		stateNodes = new Vector<StateNode>();
		signalNodes = new Vector<SignalNode>();
		annotations = new Vector<AnnotationNode>();
		edges = new Vector<Edge>();
	}
	
	public void getSize(Vector2d size){
		double minX = 1000000;
		double maxX = -1000000;
		double minY = 1000000;
		double maxY = -1000000;
		
		for(Element e : elements){
			Vector2d p = e.getPosition();
			if(p.getX() < minX) minX = p.getX();
			if(p.getX() > maxX) maxX = p.getX();
			if(p.getY() < minY) minY = p.getY();
			if(p.getY() > maxY) maxY = p.getY();
		}
		if(minX == 1000000 || maxX == -1000000
		|| minY == 1000000 || maxY == -1000000) size.set(0,0);
		else size.set(maxX - minX, maxY - minY);
	}
	
	public synchronized Vector<Interactable> getInteractables(){
		return interactables.getElements();
	}
	
	public synchronized Vector<Drawable> getDrawables(){
		return drawables.getElements();
	}

	public synchronized StateMachineNode createStateMachineNode(
			double x, double y)
	{
		StateMachineNode n = new StateMachineNode(
				this, chargeDomains.get(0), x,y,400.0,300.0);
		n.setName("State Machine " + StateMachineNode.nextID());
		
		addElement(n, LAYER_STATE_MACHINE_NODE);
		return n;
	}
	
	public synchronized StateNode createStateNode(
			StateMachineNode sm, double x, double y)
	{
		StateNode n = new StateNode(sm, x,y,100.0);
		n.setName("State\n" + StateNode.nextID());
		addElement(n, LAYER_STATE_NODE);
		return n;
	}
	
	public synchronized SignalNode createSignalNode(
			StateMachineNode sm, double x, double y)
	{
		SignalNode n = new SignalNode(sm, x,y,300.0,70.0);
		n.setName("Signal " + SignalNode.nextID());
		addElement(n, LAYER_SIGNAL_NODE);
		return n;
	}

	public synchronized PortNode createPortNode(
			StateMachineNode sm, double x, double y)
	{
		PortNode n = new PortNode(sm, x,y, 300.0,70.0);
		n.setName("Port " + PortNode.nextID());
		
		connect(sm, n);
		
		addElement(n, LAYER_SIGNAL_NODE);
		return n;
	}
	
	public synchronized AnnotationNode createAnnotation(Node n){
		Vector2d v = new Vector2d();
		v.randomize();
		v.add(n.getPosition());
		
		AnnotationNode a = new AnnotationNode(n, v.getX(), v.getY());
		
		addElement(a, LAYER_ANNOTATION_NODE);
		return a;
	}
	
	public synchronized void createStateConnection(StateNode base, double x1, double y1,
			double x2, double y2)
	{
		StateConnectionNode a = new StateConnectionNode(
				this, base.getToplevelChargeDomain(), x2, y2, 15.0);
		StateConnectionNode b = new StateConnectionNode(
				this, base.getToplevelChargeDomain(), x2, y2, 15.0);
		Edge e = new Edge(this, a, b);
		
		connect(base,a,true);
		
		a.setPeer(b);
		b.setPeer(a);
		a.setEdge(e);
		b.setEdge(e);
		addElement(b, LAYER_CONNECTION_NODE);
		addElement(e, LAYER_CONNECTION_EDGE);
		addElement(a, LAYER_CONNECTION_NODE);
		
		createAnnotation(a).textBlock.setText("empty annotation");
	}
	
	public synchronized void createSignalConnection(StateNode base, double x1, double y1,
			double x2, double y2)
	{
		StateConnectionNode a = new StateConnectionNode(
				this, base.getToplevelChargeDomain(), x2, y2, 15.0);
		SignalConnectionNode b = new SignalConnectionNode(
				this, base.getToplevelChargeDomain(), x2, y2, 15.0);
		Edge e = new Edge(this, a, b);
		
		connect(base,a,true);
		
		a.setPeer(b);
		b.setPeer(a);
		a.setEdge(e);
		b.setEdge(e);
		addElement(b, LAYER_CONNECTION_NODE);
		addElement(e, LAYER_CONNECTION_EDGE);
		addElement(a, LAYER_CONNECTION_NODE);
		
		createAnnotation(a).textBlock.setText("empty annotation");
	}
	
	private synchronized void addElement(Element e, int where){
		e.world = this;
		elements.add(e);
		animated.add(e);
		
		drawables.insert(e, where);
		
		if(e instanceof Interactable){
			interactables.insert((Interactable)e, where);
		}
		if(e instanceof StateNode){
			stateNodes.add((StateNode)e);
		}
		if(e instanceof Edge){
			edges.add((Edge)e);
		}
		if(e instanceof AnnotationNode){
			annotations.add((AnnotationNode)e);
		}
		if(e instanceof SignalNode){
			signalNodes.add((SignalNode)e);
		}
	}

	synchronized void removeElement(Element e){
		System.out.println("removing " + e);
		
		while(elements.remove(e));
		while(animated.remove(e));
		drawables.remove(e);
		
		if(e instanceof Interactable){
			interactables.remove((Interactable)e);
		}
		if(e instanceof StateNode){
			while(stateNodes.remove((StateNode)e));
		}
		if(e instanceof Edge){
			while(edges.remove((Edge)e));
		}
		if(e instanceof AnnotationNode){
			while(annotations.remove((AnnotationNode)e));
		}
	}
	
	public synchronized void dissolve(Element e){
		e.dissolve();
	}
	
	public synchronized void addChargeDomain(ChargeDomain d){
		animated.add(d);
		chargeDomains.add(d);
	}
	
	public synchronized void removeChargeDomain(ChargeDomain d){
		while(animated.remove(d));
		while(chargeDomains.remove(d));
	}
	
	
	public synchronized void update(double dt){
		for(int i = 0; i < animated.size(); i++){
			animated.get(i).applyForce();
		}
		for(int i = 0; i < animated.size(); i++){
			animated.get(i).update(dt);
		}
	}

	public synchronized StateNode getStateNode(double x, double y){
		for(StateNode n : stateNodes){
			if(n.contains(x,y)){
				return n;
			}
		}
		return null;
	}

	public synchronized SignalNode getSignalNode(double x, double y){
		for(SignalNode n : signalNodes){
			if(n.contains(x,y)){
				return n;
			}
		}
		return null;
	}
	
	public synchronized Interactable getInteractable(double x, double y){
		Vector<Interactable> ia = interactables.getElements();
		for(int i = ia.size() - 1; i >= 0; i--){
			if(ia.get(i).contains(x,y)){
				return ia.get(i);
			}
		}
		return null;
	}
	
	public synchronized Vector<ChargeDomain> getChargeDomains() {
		return chargeDomains;
	}
}
