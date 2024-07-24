import React from 'react';
import { Box, Text, Heading, VStack, UnorderedList, ListItem, useColorModeValue } from "@chakra-ui/react";

const IntroductionSection: React.FC = () => {
  const bgColor = useColorModeValue('white', 'gray.800');
  const borderColor = useColorModeValue('gray.200', 'gray.700');
  const headingColor = useColorModeValue('brand.600', 'brand.400');

  return (
    <Box as="section" width="full" p={8} bg={bgColor} borderRadius="lg" mb={8} boxShadow="xl" borderWidth={1} borderColor={borderColor}>
      <VStack spacing={6} align="start">
        <Text fontSize="lg">
          Rupaya Bridge allows you to seamlessly transfer your RUPX tokens between Rupaya and Binance Smart Chain networks.
        </Text>
        <Text fontSize="lg" fontWeight="bold">
          Benefits of using Rupaya Bridge:
        </Text>
        <UnorderedList spacing={2} pl={4}>
          <ListItem>Fast and secure transfers</ListItem>
          <ListItem>Low transaction fees</ListItem>
          <ListItem>Easy-to-use interface</ListItem>
          <ListItem>Expand your DeFi opportunities</ListItem>
        </UnorderedList>
      </VStack>
    </Box>
  );
};

export default IntroductionSection;