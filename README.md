ReconOS
=======

This is the main source code and documentation repository for ReconOS
<http://www.reconos.de>.

ReconOS in a nutshell
---------------------

ReconOS is a programming model, an execution environment, an operating system
extension, a hardware architecture, a research project, and a development
playground.

Originally developed within the context of a university research project and a
PhD thesis, ReconOS is a way to bring some of the convenience of a
software-like programming model to the detail-ridden world of dynamically
reconfigurable hardware design. With ReconOS, you can model a concurrent
application for reconfigurable systems-on-chip (rSoC) using both software and
hardware threads. The interactions between all threads are handled through
common POSIX-like abstractions such as mailboxes, semaphores, or shared
memory, hiding the complexities of bus access protocols, memory spaces,
register files and interrupt handling.


Licensing
---------

Copyright (C) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
Computer Engineering Group, University of Paderborn, Germany

All rights reserved.

Except where otherwise indicated, ReconOS is free software: you can
redistribute it and/or modify it under the terms of the GNU General Public
License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
ReconOS (in the file COPYING). If not, see <http://www.gnu.org/licenses/>.

Parts of ReconOS which are not distributed under the terms of the GPL have
their own COPYING file in the respective subdirectory. Examples are the eCos
source code and its ReconOS extensions, which fall under a modified GPL
variant.

If you would like to use ReconOS under a different license, please contact
<license@reconos.de>.


Getting Started
---------------

ReconOS is under continuous development and is being used in several research
projects with both academic and industrial partners. We welcome all forms of
contribution and are actively seeking users and developers interested in
integrating reconfigurable logic and software-based operating systems.

For guides and other resources pertaining to the use and/or development of
ReconOS and instructions on how to download ReconOS and participate in its
development, please refer to <http://www.reconos.de/>. There you will also find
information on how to contact the ReconOS community through e-Mail, mailing
lists and other means of communication.


Subdirectories
--------------
    
    attic/    defunct, but potentially useful code (e.g. layout editor)

    core/     core ReconOS functions, such as hardware modules, OS integration,
              command definitions, and FPGA definitions

    demos/    demonstration projects, tutorials

    doc/      documentation sources (users guide), source header templates

    support/  code templates, sample threads, reference designs

    tests/    automated tests and benchmarks

    tools/    build tool chain and other scripts (impact download, unlock etc.)

- luebbers, 10.08.2010
