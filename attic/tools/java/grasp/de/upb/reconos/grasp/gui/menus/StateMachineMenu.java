package de.upb.reconos.grasp.gui.menus;


import java.awt.event.ActionEvent;

import de.upb.reconos.grasp.objects.StateMachineNode;
import de.upb.reconos.grasp.objects.World;


public class StateMachineMenu extends BasicMenu {

	private static final long serialVersionUID = 1L;
	private StateMachineNode node;
	
	public StateMachineMenu(World w){
		super(w);
		addItem("New State");
		addItem("New Signal");
		addItem("New Port");
		addSeparator();
		addItem("Remove This State Machine");
		addSeparator();
		addItem("Options");
	}
	
	public void setStateMachineNode(StateMachineNode n){
		node = n;
	}
	
	public void actionPerformed(ActionEvent e) {
		String cmd = e.getActionCommand().toLowerCase();
		double wx = worldPosition.getX();
		double wy = worldPosition.getY();
		
		if(cmd.equals("new state")){
			world.createStateNode(node, wx,wy);
		}
		if(cmd.equals("new signal")){
			world.createSignalNode(node, wx,wy);
		}
		if(cmd.equals("new port")){
			world.createPortNode(node, wx,wy);
		}
		if(cmd.equals("remove this state machine")){
			world.dissolve(node);
			node = null;
		}
	}
}
