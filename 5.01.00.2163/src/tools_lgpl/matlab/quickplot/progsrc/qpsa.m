function handleOut=qpsa(handleIn)
%QPSA Get handle to the current QuickPlot axis.
%   H = QPSA returns the handle to the axis currently selected in the
%   PlotManager of QuickPlot.
%
%   See also QPSF, GCF, GCA.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2012 Stichting Deltares.                                     
%                                                                               
%   This library is free software; you can redistribute it and/or                
%   modify it under the terms of the GNU Lesser General Public                   
%   License as published by the Free Software Foundation version 2.1.                         
%                                                                               
%   This library is distributed in the hope that it will be useful,              
%   but WITHOUT ANY WARRANTY; without even the implied warranty of               
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU            
%   Lesser General Public License for more details.                              
%                                                                               
%   You should have received a copy of the GNU Lesser General Public             
%   License along with this library; if not, see <http://www.gnu.org/licenses/>. 
%                                                                               
%   contact: delft3d.support@deltares.nl                                         
%   Stichting Deltares                                                           
%   P.O. Box 177                                                                 
%   2600 MH Delft, The Netherlands                                               
%                                                                               
%   All indications and logos of, and references to, "Delft3D" and "Deltares"    
%   are registered trademarks of Stichting Deltares, and remain the property of  
%   Stichting Deltares. All rights reserved.                                     
%                                                                               
%-------------------------------------------------------------------------------
%   http://www.deltaressystems.com
%   $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/tags/5.01.00.2163/src/tools_lgpl/matlab/quickplot/progsrc/qpsa.m $
%   $Id: qpsa.m 1147 2011-12-31 23:43:35Z jagers $

if nargin>0
    d3d_qp('selectfigure',handleIn);
    d3d_qp('selectaxes',handleIn);
end
if nargout>0
    handleOut = d3d_qp('selectedaxes');
end
