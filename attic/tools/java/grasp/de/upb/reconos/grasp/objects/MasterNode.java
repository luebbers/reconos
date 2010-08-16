package de.upb.reconos.grasp.objects;


import java.util.Vector;

import de.upb.reconos.grasp.physics.ChargeDomain;


public abstract class MasterNode extends ChargeDomainNode {

	private Vector<ConnectionNode> slaves;
	
	public MasterNode(World w, ChargeDomain toplevel, double x, double y){
		super(w, toplevel, x, y);
		slaves = new Vector<ConnectionNode>();
	}
	
	public void attach(ConnectionNode slave){
		if(!accepts(slave)) throw new RuntimeException();
		slaves.add(slave);
	}
	
	public void detach(ConnectionNode slave){
		while(slaves.remove(slave));
		disconnect(slave);
	}
	
	public void dissolve(){
		while(slaves.size() > 0){
			World.disconnect(this, slaves.get(0));
		}
		super.dissolve();
	}
	
	public boolean accepts(ConnectionNode slave){
		return true;
	}
}
