package de.upb.reconos.grasp.objects;

import de.upb.reconos.grasp.physics.ChargeDomain;

public abstract class ChargeDomainNode extends Node {
	private ChargeDomain localChargeDomain;
	
	public ChargeDomainNode(World w, ChargeDomain toplevel, double x, double y){
		super(w, toplevel, x, y);
		localChargeDomain = new ChargeDomain();
		world.addChargeDomain(localChargeDomain);
	}
	
	public ChargeDomain getLocalChargeDomain() {
		return localChargeDomain;
	}
	
	public void dissolve(){
		world.removeChargeDomain(getLocalChargeDomain());
		super.dissolve();
	}
}
