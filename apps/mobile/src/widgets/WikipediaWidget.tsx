import { HStack, Spacer, Text, VStack, ZStack } from '@expo/ui/swift-ui';
import { createWidget, type WidgetEnvironment } from 'expo-widgets';
import {
  containerBackground,
  font,
  foregroundStyle,
  frame,
  lineLimit,
  padding,
  widgetURL,
} from '@expo/ui/swift-ui/modifiers';

export type WikipediaWidgetProps = {
  title: string;
  description: string;
  extract: string;
  url: string;
};

const WikipediaWidget = (props: WikipediaWidgetProps, environment: WidgetEnvironment) => {
  'widget';

  const isSmall = environment.widgetFamily === 'systemSmall';
  const textColor = environment.colorScheme === 'dark' ? '#F5F4F0' : '#17181C';
  const mutedColor = environment.colorScheme === 'dark' ? '#B9B8B2' : '#6B6C72';

  return (
    <ZStack
      modifiers={[
        containerBackground(environment.colorScheme === 'dark' ? '#15171B' : '#F5F4F0', 'widget'),
        widgetURL(props.url),
      ]}>
      <VStack
        alignment="leading"
        spacing={isSmall ? 7 : 9}
        modifiers={[frame({ maxWidth: Infinity, maxHeight: Infinity }), padding({ all: 16 })]}>
        <HStack>
          <Text modifiers={[font({ weight: 'bold', size: 10 }), foregroundStyle(mutedColor)]}>
            WIKIPEDIA
          </Text>
          <Spacer />
          <Text modifiers={[font({ size: 10 }), foregroundStyle(mutedColor)]}>↗</Text>
        </HStack>

        <Text
          modifiers={[
            font({ weight: 'medium', size: isSmall ? 20 : 22 }),
            foregroundStyle(textColor),
            lineLimit(isSmall ? 3 : 2),
          ]}>
          {props.title}
        </Text>

        <Spacer />

        <Text modifiers={[font({ size: isSmall ? 11 : 12 }), foregroundStyle(mutedColor), lineLimit(isSmall ? 2 : 4)]}>
          {isSmall && props.description ? props.description : props.extract}
        </Text>
      </VStack>
    </ZStack>
  );
};

export default createWidget('WikipediaWidget', WikipediaWidget);
