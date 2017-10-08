#pragma once

#include <string>

namespace coolutility
{

class CoolUtility
{
public:
	std::string makeString(const char *message) const
	{
		return std::string(message);
	}
};	
	
}
