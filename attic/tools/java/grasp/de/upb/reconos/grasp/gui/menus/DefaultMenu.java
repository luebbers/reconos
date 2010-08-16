package de.upb.reconos.grasp.gui.menus;


import java.awt.event.ActionEvent;

import de.upb.reconos.grasp.objects.World;


public class DefaultMenu extends BasicMenu {

	private static final long serialVersionUID = 1L;
	public DefaultMenu(World w){
		super(w);
		addItem("New State Machine");
		addSeparator();
		addItem("Options");
	}	
	public void actionPerformed(ActionEvent e) {
		String cmd = e.getActionCommand().toLowerCase();
		double wx = worldPosition.getX();
		double wy = worldPosition.getY();
		
		if(cmd.equals("new state machine")){
			world.createStateMachineNode(wx,wy);
		}
	}
}
