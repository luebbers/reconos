package de.upb.reconos.grasp.objects;

import de.upb.reconos.grasp.physics.ChargeDomain;

public abstract class ConnectionNode extends Node {

	private ConnectionNode peer;
	private MasterNode master;
	private Edge edge;
	private boolean fixed;
	private boolean dissolving;
	
	public ConnectionNode(World w, ChargeDomain toplevel,
			double x, double y)
	{
		super(w,toplevel,x,y);
		fixed = false;
		dissolving = false;
	}
	
	public MasterNode getMaster(){ return master; }
	public ConnectionNode getPeer() { return peer; }
	
	public void setEdge(Edge e){
		if(edge != null) throw new RuntimeException();
		requires(e);
		edge = e;
	}
	
	public void setPeer(ConnectionNode n){
		if(peer != null) throw new RuntimeException();
		requires(n);
		peer = n;
	}
	
	public void attach(MasterNode n){
		if(!accepts(n)) {
			System.err.println("attach failed");
			return;
		}
		if(master != null) detach();
		master = n;
		getToplevelChargeDomain().remove(getCenterPoint());
		n.getLocalChargeDomain().add(getCenterPoint());
	}
	
	public void detach(){
		if(master == null) return;
		
		master.getLocalChargeDomain().remove(getCenterPoint());
		getToplevelChargeDomain().add(getCenterPoint());
		
		master = null;
	}
	
	public void dissolve(){
		if(dissolving) return;
		dissolving = true;
		
		if(master != null){
			World.disconnect(master, this);
		}
		super.dissolve();
	}
	
	public void onClick(int button, double x, double y){
		if(!fixed && master != null) World.disconnect(master,this);
		else dissolve();
	}
	
	public void fix(){
		if(master == null) throw new RuntimeException();
		requires(master);
		fixed = true;
	}
	
	public boolean accepts(MasterNode n) {
		if(master != null) return false;
		if(getPeer() != null && getPeer().getMaster() != null){
			return getPeer().getMaster() != n;
		}
		return true;
	}
}
