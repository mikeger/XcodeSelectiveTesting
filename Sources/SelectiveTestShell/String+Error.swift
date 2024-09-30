//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

#if compiler(>=6)
extension String: @retroactive Error {}
#else
extension String: Error {}
#endif
